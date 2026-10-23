#!/usr/bin/env python3
"""Convert a single PDF to markdown via pymupdf4llm.

Usage: convert.py <pdf-path> <out-dir>

Mirrors marker's old output layout: <out-dir>/<pdf-basename>/<pdf-basename>.md
"""
import os
import re
import sys

import pymupdf
import pymupdf4llm

BR_RE = re.compile(r"<br\s*/?>", re.IGNORECASE)
# characters that break a markdown/Obsidian link target (# is a heading
# anchor, % reads as URL-encoding, ^ a block ref, | an alias, etc.)
UNSAFE_LINK_CHARS_RE = re.compile(r"[\s#%?^|\[\]()<>:*\"\\`]+")
TABLE_SEP_RE = re.compile(r"^\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)*\|?$")


def pad_empty_header_cells(md_text):
    """Ensure table header cells have at least a space.

    A header row with a blank cell (pymupdf4llm emits "||" for those)
    renders as a collapsed, misaligned header in Obsidian.
    """
    lines = md_text.split("\n")
    for i in range(len(lines) - 1):
        if lines[i].startswith("|") and TABLE_SEP_RE.match(lines[i + 1].strip()):
            cells = lines[i].split("|")
            cells[1:-1] = [cell if cell.strip() else " " for cell in cells[1:-1]]
            lines[i] = "|".join(cells)
    return "\n".join(lines)


def unwrap_br_tags(md_text):
    """Replace <br> with a real newline, except inside table rows.

    pymupdf4llm emits <br> for line breaks in prose (safe to unwrap) but
    also uses it inside markdown table cells to pack multi-line cell
    content onto the row's single physical line, since a literal newline
    there would split the row and break the table. Leave those alone.
    """
    lines = md_text.split("\n")
    return "\n".join(
        line if line.lstrip().startswith("|") else BR_RE.sub("\n", line)
        for line in lines
    )


def main():
    pdf_path, out_dir = os.path.abspath(sys.argv[1]), sys.argv[2]
    name = os.path.splitext(os.path.basename(pdf_path))[0]
    target_dir = os.path.abspath(os.path.join(out_dir, name))
    os.makedirs(target_dir, exist_ok=True)

    # pymupdf4llm makes the image path relative to cwd and then rewrites
    # spaces/brackets/dashes in it - but saves to that rewritten path, so
    # any such character in out_dir or the PDF name sends the save to a
    # directory that doesn't exist. Running from target_dir leaves only
    # "images/<file>" to be rewritten, and also makes the image links in
    # the markdown relative to the .md file.
    os.chdir(target_dir)

    # Image files are named after the document. Opening from a stream
    # leaves the document unnamed, so pymupdf4llm falls back to the
    # filename we give it - one with no characters that break links.
    with open(pdf_path, "rb") as f:
        doc = pymupdf.open(stream=f.read(), filetype="pdf")
    md_text = pymupdf4llm.to_markdown(
        doc,
        filename=UNSAFE_LINK_CHARS_RE.sub("_", name) + ".pdf",
        write_images=True,
        image_path="images",
        use_ocr=False,
    )
    md_text = unwrap_br_tags(md_text)
    md_text = pad_empty_header_cells(md_text)

    out_file = os.path.join(target_dir, f"{name}.md")
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(md_text)


if __name__ == "__main__":
    main()

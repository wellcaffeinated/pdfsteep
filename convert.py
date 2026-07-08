#!/usr/bin/env python3
"""Convert a single PDF to markdown via pymupdf4llm.

Usage: convert.py <pdf-path> <out-dir>

Mirrors marker's old output layout: <out-dir>/<pdf-basename>/<pdf-basename>.md
"""
import os
import sys

import pymupdf4llm


def main():
    pdf_path, out_dir = sys.argv[1], sys.argv[2]
    name = os.path.splitext(os.path.basename(pdf_path))[0]
    target_dir = os.path.join(out_dir, name)
    os.makedirs(target_dir, exist_ok=True)

    md_text = pymupdf4llm.to_markdown(
        pdf_path,
        write_images=True,
        image_path=os.path.join(target_dir, "images"),
        use_ocr=False,
    )

    out_file = os.path.join(target_dir, f"{name}.md")
    with open(out_file, "w", encoding="utf-8") as f:
        f.write(md_text)


if __name__ == "__main__":
    main()

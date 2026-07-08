# pdfsteep

Drop a PDF in a folder, get a markdown file back. A small docker-compose
wrapper that watches `IN_DIR` and converts any PDF that shows up into
`OUT_DIR`, using [pymupdf4llm](https://pymupdf.readthedocs.io/en/latest/pymupdf4llm/)
(pure PyMuPDF text/layout extraction, no ML models).

Internal-use tool. No OCR — works on native-text PDFs, not scanned images.
(Originally built on [datalab-to/marker](https://github.com/datalab-to/marker),
swapped out because marker's local model pipeline was peaking at ~11 GB RAM
per conversion, which isn't viable on this box. pymupdf4llm has no model
pipeline at all — tens of MB, not gigabytes — at the cost of OCR support and
some accuracy on complex tables/multi-column layouts.)

## Usage

```bash
cp .env.example .env
# edit .env: set DATA_DIR / PUID / PGID as needed

just build
just up
just logs
```

`DATA_DIR` (default `./data`) is bind-mounted to `/data` in the container.
`IN_DIR` and `OUT_DIR` are paths *inside the container* — they default to
`/data/in` and `/data/out`, both under that one mount, so nothing extra is
needed for the common case. Drop a PDF into `DATA_DIR/in`. Once converted,
`DATA_DIR/out/<pdf-name>/<pdf-name>.md` (plus any extracted images) will
appear.

### In-place conversion

Since `IN_DIR`/`OUT_DIR` are container-side paths rather than separate host
mounts, they can point at the same directory — e.g. set both to `/data` — so
markdown gets written alongside the PDF that produced it, out of a single
watched folder.

## Configuration

Set via `.env` (see `.env.example`) or directly in the environment:

| Variable          | Default        | Purpose                                            |
|--------------------|----------------|-----------------------------------------------------|
| `PUID` / `PGID`    | `1000` / `1000` | UID/GID the converter process runs as              |
| `DATA_DIR`         | `./data`       | Host path bind-mounted to `/data`                  |
| `IN_DIR`           | `/data/in`     | Container-internal path watched for new PDFs       |
| `OUT_DIR`          | `/data/out`    | Container-internal path markdown is written to     |
| `TZ`               | `Etc/UTC`      | Container timezone                                 |

## Smoketest

```bash
just smoketest
```

Downloads a real paper from arXiv into a temp data dir, brings up an
isolated compose project (`pdfsteep-smoketest`) pointed at it, waits for
the converted markdown to appear, then tears the stack down and deletes the
temp dir — pass or fail. Conversion is CPU-parsing only (no model
inference), so this finishes in seconds; default timeout is 60s, override
with `SMOKETEST_TIMEOUT`.

If something is left behind (e.g. the run was killed mid-test), clean up
with:

```bash
just clean-smoketest
```

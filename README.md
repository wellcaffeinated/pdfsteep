# marker-watch

Drop a PDF in a folder, get a markdown file back. A small docker-compose
wrapper around [datalab-to/marker](https://github.com/datalab-to/marker)
that watches `IN_DIR` and converts any PDF that shows up into `OUT_DIR`.

Internal-use tool, CPU inference by default.

## Usage

```bash
cp .env.example .env
# edit .env: set IN_DIR / OUT_DIR / PUID / PGID as needed

just build
just up
just logs
```

Drop a PDF into `IN_DIR`. Once converted, `OUT_DIR/<pdf-name>/<pdf-name>.md`
(plus a `_meta.json` and any extracted images) will appear, courtesy of
marker's own output layout.

## Configuration

Set via `.env` (see `.env.example`) or directly in the environment:

| Variable          | Default        | Purpose                                            |
|--------------------|----------------|-----------------------------------------------------|
| `PUID` / `PGID`    | `1000` / `1000` | UID/GID the converter process runs as              |
| `IN_DIR`           | `./data/in`    | Host path watched for new PDFs                     |
| `OUT_DIR`          | `./data/out`   | Host path converted markdown is written to         |
| `CONFIG_DIR`       | `./config`     | Host path for marker's model-weight cache          |
| `TZ`               | `Etc/UTC`      | Container timezone                                 |
| `OUTPUT_FORMAT`    | `markdown`     | Passed to `marker_single --output_format`          |
| `TORCH_DEVICE`     | `cpu`          | `cpu` or `cuda` (see GPU note below)                |
| `MARKER_EXTRA_ARGS`| _(empty)_      | Extra flags appended to every `marker_single` call, e.g. `--use_llm` |

First run downloads marker's model weights (a few GB) into `CONFIG_DIR`;
subsequent runs reuse the cache.

## GPU

The default image installs the CPU build of torch. For GPU inference,
rebuild against a CUDA-enabled base image, set `TORCH_DEVICE=cuda`, and
uncomment the `deploy.resources` block in `docker-compose.yml` (requires the
NVIDIA container toolkit on the host).

## Smoketest

```bash
just smoketest
```

Downloads a real paper from arXiv into a temp `IN_DIR`, brings up an
isolated compose project pointed at temp in/out dirs, waits for the
converted markdown to appear, then tears the stack down and deletes the temp
dirs — pass or fail. If something is left behind (e.g. the run was killed
mid-test), clean up with:

```bash
just clean-smoketest
```

Note: the smoketest reuses the real `CONFIG_DIR` (model cache) so it doesn't
redownload multi-GB model weights on every run.

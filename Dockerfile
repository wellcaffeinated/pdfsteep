FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    IN_DIR=/data/in \
    OUT_DIR=/data/out

RUN apt-get update && apt-get install -y --no-install-recommends \
        inotify-tools \
        gosu \
        ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# pymupdf4llm: pure PyMuPDF-based PDF->markdown, no ML models, no GPU/CPU
# inference pipeline, no multi-GB weight downloads. No OCR (native-text PDFs
# only) - trades that off for a footprint in the tens of MB instead of
# multiple GB.
RUN pip install pymupdf4llm

RUN groupadd -g 1000 watcher \
    && useradd -u 1000 -g watcher -M -s /usr/sbin/nologin watcher

COPY entrypoint.sh /entrypoint.sh
COPY watch.sh /usr/local/bin/watch.sh
COPY convert.py /usr/local/bin/convert.py
RUN chmod +x /entrypoint.sh /usr/local/bin/watch.sh /usr/local/bin/convert.py

VOLUME ["/data"]

ENTRYPOINT ["/entrypoint.sh"]

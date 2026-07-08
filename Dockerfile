FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    IN_DIR=/data/in \
    OUT_DIR=/data/out \
    OUTPUT_FORMAT=markdown \
    TORCH_DEVICE=cpu \
    HOME=/config

RUN apt-get update && apt-get install -y --no-install-recommends \
        inotify-tools \
        gosu \
        curl \
        ca-certificates \
        libgl1 \
        libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

# CPU wheel first, so `pip install marker-pdf` doesn't pull the much larger
# CUDA build. Override TORCH_DEVICE=cuda + rebuild with a CUDA base image
# for GPU use.
RUN pip install --index-url https://download.pytorch.org/whl/cpu torch \
    && pip install marker-pdf

RUN groupadd -g 1000 marker \
    && useradd -u 1000 -g marker -M -d /config -s /usr/sbin/nologin marker

COPY entrypoint.sh /entrypoint.sh
COPY watch.sh /usr/local/bin/watch.sh
RUN chmod +x /entrypoint.sh /usr/local/bin/watch.sh

VOLUME ["/data/in", "/data/out", "/config"]

ENTRYPOINT ["/entrypoint.sh"]

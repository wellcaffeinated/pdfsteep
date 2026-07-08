set shell := ["bash", "-uc"]

default:
    @just --list

# build the image
build:
    docker compose build

# start the watcher in the background
up:
    docker compose up -d

# stop and remove the container
down:
    docker compose down

# follow container logs
logs:
    docker compose logs -f

restart: down up

# end-to-end test: downloads an arXiv PDF, drops it in a temp data dir,
# waits for markdown to appear, then cleans up after itself
smoketest:
    ./smoketest/smoketest.sh

# remove any leftover smoketest temp dirs / containers
clean-smoketest:
    docker compose -p pdfsteep-smoketest down --remove-orphans 2>/dev/null || true
    rm -rf smoketest/tmp.*

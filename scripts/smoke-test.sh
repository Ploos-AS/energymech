#!/bin/sh
set -eu

image="${1:-energymech:test}"

docker run --rm --entrypoint /usr/local/bin/energymech "$image" --help >/tmp/energymech-help.txt 2>&1 || true
docker run --rm --entrypoint sh "$image" -c 'id -u | grep -qx 1000; test -x /usr/local/bin/energymech; test -x /usr/local/bin/energymech-entrypoint; test -x /usr/local/bin/energymech-healthcheck'

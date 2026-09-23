#!/bin/sh
set -eu

IMAGE="${1:-energymech:test}"
TMP="$(mktemp -d)"
SRC="$TMP/source"
RESTORED="$TMP/restored"
NAME=energymech-persistence-test

cleanup() {
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  rm -rf "$TMP"
}
trap cleanup EXIT INT TERM

mkdir -p "$SRC" "$RESTORED"
printf '%s\n' 'persistence-marker' >"$SRC/state.marker"
printf '%s\n' '# persistence test configuration' >"$SRC/energymech.conf"
chmod 600 "$SRC/energymech.conf"

tar -C "$SRC" -cf "$TMP/backup.tar" .
tar -C "$RESTORED" -xf "$TMP/backup.tar"

cmp "$SRC/state.marker" "$RESTORED/state.marker"
cmp "$SRC/energymech.conf" "$RESTORED/energymech.conf"

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$RESTORED:/data" \
  --entrypoint /bin/sh \
  "$IMAGE" -c 'test -r /data/energymech.conf && test "$(cat /data/state.marker)" = persistence-marker'

docker run -d --name "$NAME" \
  --user "$(id -u):$(id -g)" \
  -v "$RESTORED:/data" \
  --entrypoint /bin/sh \
  "$IMAGE" -c 'sleep 30' >/dev/null

docker rm -f "$NAME" >/dev/null

docker run --rm \
  --user "$(id -u):$(id -g)" \
  -v "$RESTORED:/data" \
  --entrypoint /bin/sh \
  "$IMAGE" -c 'test "$(cat /data/state.marker)" = persistence-marker'

echo "PASS: /data backup, restore, and container recreation preserve persistent data"

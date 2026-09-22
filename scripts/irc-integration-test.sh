#!/bin/sh
set -eu
IMAGE="${1:-energymech:test}"
NET=energymech-ci
IRCD=energymech-ircd
BOT=energymech-bot
TMP="$(mktemp -d)"
cleanup(){ docker rm -f "$BOT" "$IRCD" >/dev/null 2>&1 || true; docker network rm "$NET" >/dev/null 2>&1 || true; rm -rf "$TMP"; }
trap cleanup EXIT INT TERM
mkdir -p "$TMP/data"
cat >"$TMP/data/energymech.conf" <<'EOF'
set ctimeout 15
server ircd 6667 @ci
nick 4242 emechtst
set servergroup ci
set userfile mech.passwd
set ident energymech
set ircname EnergyMech CI
set cmdchar .
join #energymech-ci
set pub 1
EOF
chmod 600 "$TMP/data/energymech.conf" "$TMP/data/mech.passwd"
docker network create "$NET" >/dev/null
docker run -d --name "$IRCD" --network "$NET" ghcr.io/ergochat/ergo:stable >/dev/null
for i in $(seq 1 30); do
  docker logs "$IRCD" 2>&1 | grep -qi 'server' && break || true
  sleep 1
done
docker run -d --name "$BOT" --network "$NET" \
  -v "$TMP/data:/data" \
  --user "$(id -u):$(id -g)" \
  "$IMAGE" >/dev/null
for i in $(seq 1 45); do
  LOG="$(docker logs "$IRCD" 2>&1 || true)"
  if printf '%s\n' "$LOG" | grep -q 'emechtst'; then
    echo "PASS: EnergyMech registered with isolated IRC server"
    docker ps --filter "name=$BOT" --format '{{.Status}}' | grep -q '^Up '
    exit 0
  fi
  docker ps --filter "name=$BOT" --format '{{.Status}}' | grep -q '^Up ' || { docker logs "$BOT"; exit 1; }
  sleep 1
done
echo "FAIL: EnergyMech did not register with IRC server" >&2
docker logs "$BOT" >&2 || true
docker logs "$IRCD" >&2 || true
exit 1

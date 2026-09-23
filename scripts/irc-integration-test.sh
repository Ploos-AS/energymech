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
docker network create "$NET" >/dev/null
docker run -d --name "$IRCD" --network "$NET" ghcr.io/ergochat/ergo:stable >/dev/null
for i in $(seq 1 30); do
  docker logs "$IRCD" 2>&1 | grep -qi 'Server running' && break || true
  sleep 1
done
IRCD_IP="$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$IRCD")"
[ -n "$IRCD_IP" ] || { echo "FAIL: unable to determine IRC server IP" >&2; exit 1; }
cat >"$TMP/data/energymech.conf" <<EOF
set ctimeout 15
set servergroup ci
server $IRCD_IP 6667 @ci
set servergroup ci
nick 4242 emechtst
set servergroup ci
set userfile mech.passwd
set ident energymech
set ircname EnergyMech CI
set cmdchar .
join #energymech-ci
set pub 1
EOF
cat >"$TMP/data/mech.passwd" <<'EOF'
user	ciowner
mask	*!*@*
chan	*
opt	p0u100
pass	ci-only-not-a-real-password
EOF
chmod 600 "$TMP/data/energymech.conf" "$TMP/data/mech.passwd"
docker run -d --name "$BOT" --network "$NET" \
  -v "$TMP/data:/data" \
  --user "$(id -u):$(id -g)" \
  "$IMAGE" >/dev/null
sleep 2
docker ps -a --filter "name=$BOT"
docker logs "$BOT" || true
for i in $(seq 1 45); do
  LOG="$(docker logs "$IRCD" 2>&1 || true)"
  if printf '%s\n' "$LOG" | grep -q 'emechtst'; then
    echo "PASS: EnergyMech registered with isolated IRC server"
    docker ps --filter "name=$BOT" --format '{{.Status}}' | grep -q '^Up '

    echo "M2.2: qualifying graceful stop and restart"
    docker stop -t 10 "$BOT" >/dev/null
    [ "$(docker inspect -f '{{.State.ExitCode}}' "$BOT")" -eq 0 ] || { echo "FAIL: EnergyMech did not stop cleanly" >&2; exit 1; }
    docker start "$BOT" >/dev/null
    for j in $(seq 1 45); do
      docker ps --filter "name=$BOT" --format '{{.Status}}' | grep -q '^Up ' || { echo "FAIL: EnergyMech exited after restart" >&2; docker logs "$BOT" >&2 || true; exit 1; }
      NEWLOG="$(docker logs "$IRCD" 2>&1 || true)"
      COUNT="$(printf '%s\n' "$NEWLOG" | grep -c 'emechtst' || true)"
      if [ "$COUNT" -ge 2 ]; then
        echo "PASS: EnergyMech stopped cleanly, restarted, and reconnected"
        exit 0
      fi
      sleep 1
    done
    echo "FAIL: EnergyMech did not reconnect after restart" >&2
    docker logs "$BOT" >&2 || true
    docker logs "$IRCD" >&2 || true
    exit 1
  fi
  docker ps --filter "name=$BOT" --format '{{.Status}}' | grep -q '^Up ' || { docker logs "$BOT"; exit 1; }
  sleep 1
done
echo "FAIL: EnergyMech did not register with IRC server" >&2
docker logs "$BOT" >&2 || true
docker logs "$IRCD" >&2 || true
exit 1

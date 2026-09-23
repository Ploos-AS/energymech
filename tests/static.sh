#!/bin/sh
set -eu

test -s Dockerfile
test -s compose.yaml
test -s README.md
test -s LICENSE
test -s THIRD_PARTY_LICENSES.md
test -s rootfs/usr/local/bin/energymech-entrypoint
test -s rootfs/usr/local/bin/energymech-healthcheck
grep -q 'USER 1000:1000' Dockerfile
grep -q 'VOLUME \["/data"\]' Dockerfile
grep -q 'HEALTHCHECK' Dockerfile
grep -q 'COPY --from=builder /src/LICENSE /usr/share/licenses/energymech/LICENSE' Dockerfile
grep -q 'org.opencontainers.image.licenses="MIT AND GPL-2.0-or-later"' Dockerfile
grep -q 'ghcr.io/ploos-as/energymech' compose.yaml

test -s examples/energymech.conf.example
test -s examples/mech.passwd.example
grep -q '^set servergroup ' examples/energymech.conf.example
grep -q '^server ' examples/energymech.conf.example
grep -q '^nick ' examples/energymech.conf.example
grep -q '^set userfile mech.passwd$' examples/energymech.conf.example
! grep -Eq 'pass[[:space:]]+[^R#]' examples/mech.passwd.example

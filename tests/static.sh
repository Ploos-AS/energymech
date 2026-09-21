#!/bin/sh
set -eu

test -s Dockerfile
test -s compose.yaml
test -s README.md
test -s rootfs/usr/local/bin/energymech-entrypoint
test -s rootfs/usr/local/bin/energymech-healthcheck
grep -q 'USER 1000:1000' Dockerfile
grep -q 'VOLUME \["/data"\]' Dockerfile
grep -q 'HEALTHCHECK' Dockerfile
grep -q 'ghcr.io/ploos-as/energymech' compose.yaml

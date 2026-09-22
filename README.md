# EnergyMech OCI container

Production-oriented OCI packaging of the EnergyMech IRC bot for Docker and Podman.

This repository follows the same container conventions used by the other Ploos-AS IRC bot images: pinned upstream source, multi-stage builds, non-root runtime, persistent `/data`, health checks, Compose/Podman examples, GHCR publishing and automated qualification.

## M0 scope

- Build EnergyMech from pinned upstream source.
- Run as UID/GID 1000 without root privileges.
- Persist configuration and runtime state under `/data`.
- Provide Docker Compose and Podman/Quadlet examples.
- Provide static and smoke tests.
- Publish multi-architecture OCI images to GHCR from CI.
- Keep credentials out of the image and repository.

## Image

```text
ghcr.io/ploos-as/energymech:edge
```

Release images will use semantic version tags after the first qualified release.

## Quick start

Create a data directory and place your EnergyMech configuration there, then run:

```sh
docker compose up -d
```

The default configuration path inside the container is `/data/energymech.conf` and can be overridden with `ENERGYMECH_CONFIG`.

## Security model

- non-root runtime (`1000:1000`)
- no bundled IRC credentials
- minimal runtime dependencies
- pinned upstream revision
- `tini` as PID 1
- persistent writable data isolated to `/data`

## Status

**M0 — bootstrap**

- [x] Repository structure
- [x] Container build definition
- [x] Non-root runtime
- [x] Compose example
- [x] Podman Quadlet example
- [x] Static/smoke-test skeleton
- [x] GHCR CI workflow
- [x] Upstream revision validated by CI
- [x] Runtime IRC integration qualification
- [x] First release tag

## Licensing

Container-specific Ploos-AS files are licensed under the MIT License unless a file states otherwise. EnergyMech remains under its upstream license and is not relicensed by this repository. See `THIRD_PARTY_LICENSES.md`.

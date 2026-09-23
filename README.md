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
ghcr.io/ploos-as/energymech:0.1.0
```

The stable release is also published as `0.1` and `latest`; development builds from `main` use `edge`.

Qualified OCI architectures are `linux/amd64`, `linux/arm64`, and `linux/arm/v7`.

## Quick start

Create a data directory and place your EnergyMech configuration there, then run:

```sh
docker compose up -d
```

The default configuration path inside the container is `/data/energymech.conf` and can be overridden with `ENERGYMECH_CONFIG`.

## Backup and restore

All persistent EnergyMech configuration and state belongs under `/data`. Back up the complete directory while the container is stopped, and restore it as one unit before starting a replacement container.

Example with a bind-mounted `./data` directory:

```sh
docker compose stop
tar -C ./data -czf energymech-data-backup.tgz .
```

Restore into an empty data directory:

```sh
mkdir -p ./data
tar -C ./data -xzf energymech-data-backup.tgz
docker compose up -d
```

Keep backups protected: `/data` may contain IRC credentials and other secrets. CI qualifies archive/restore integrity and verifies that restored data survives container recreation.

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

## M2 roadmap

- Harden the runtime defaults and document the security boundary.
- [x] Add a safe example configuration with no credentials.
- [x] Add backup/restore guidance and persistence qualification for `/data`.
- [x] Qualify graceful shutdown and restart/reconnect behaviour.
- [x] Qualify and publish `linux/arm/v7` alongside amd64 and arm64.
- [x] Prepare consumption by the LeanPi IRC profile.

## LeanPi integration contract

LeanPi should consume this project as an external OCI component rather than rebuilding EnergyMech itself.

- image: `ghcr.io/ploos-as/energymech`
- stable tag: `0.1.0` (or the matching pinned release selected by LeanPi)
- development tag: `edge`
- architectures: `linux/amd64`, `linux/arm64`, `linux/arm/v7`
- persistent data: `/data`
- default configuration: `/data/energymech.conf`
- runtime UID/GID: `1000:1000`
- health: OCI `HEALTHCHECK`
- credentials: supplied externally under `/data`; never baked into the image

LeanPi profiles should pin a released image version, create and protect the persistent data directory, install configuration separately from the image, preserve `/data` during upgrades, and use the image health status for validation.

## Licensing

Container-specific Ploos-AS files are licensed under the MIT License unless a file states otherwise. EnergyMech remains under its upstream license and is not relicensed by this repository. See `THIRD_PARTY_LICENSES.md`.

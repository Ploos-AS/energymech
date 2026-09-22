# syntax=docker/dockerfile:1.7

ARG DEBIAN_VERSION=bookworm-slim

FROM debian:${DEBIAN_VERSION} AS builder
ARG ENERGYMECH_REPO=https://github.com/energymech/energymech.git
ARG ENERGYMECH_REF=master

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       build-essential ca-certificates git libssl-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone "${ENERGYMECH_REPO}" . \
    && git checkout --detach "${ENERGYMECH_REF}" \
    && ./configure \
    && make -j"$(nproc)" CFLAGS="-O2 -DDEBUG"

FROM debian:${DEBIAN_VERSION}
ARG VERSION=0.1.0
ARG ENERGYMECH_REF=master

LABEL org.opencontainers.image.title="EnergyMech" \
      org.opencontainers.image.description="Production-oriented OCI packaging of the EnergyMech IRC bot" \
      org.opencontainers.image.url="https://github.com/Ploos-AS/energymech" \
      org.opencontainers.image.source="https://github.com/Ploos-AS/energymech" \
      org.opencontainers.image.documentation="https://github.com/Ploos-AS/energymech#readme" \
      org.opencontainers.image.vendor="Ploos AS" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.revision="${ENERGYMECH_REF}" \
      org.opencontainers.image.licenses="MIT AND LicenseRef-EnergyMech"

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates libssl3 tini procps \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 energymech \
    && useradd --uid 1000 --gid 1000 --home-dir /data --create-home --shell /usr/sbin/nologin energymech

COPY --from=builder /src/src/energymech /usr/local/bin/energymech
COPY rootfs/ /

RUN chmod 0755 /usr/local/bin/energymech /usr/local/bin/energymech-entrypoint /usr/local/bin/energymech-healthcheck \
    && chown -R 1000:1000 /data

ENV HOME=/data \
    ENERGYMECH_CONFIG=/data/energymech.conf

WORKDIR /data
VOLUME ["/data"]
USER 1000:1000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD ["/usr/local/bin/energymech-healthcheck"]

ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/energymech-entrypoint"]
CMD ["run"]

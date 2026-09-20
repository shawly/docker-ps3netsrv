#
# ps3netsrv Dockerfile
#
# https://github.com/shawly/docker-ps3netsrv
#

# Set alpine version
ARG ALPINE_VERSION=3.23

# Set vars for s6 overlay
ARG S6_OVERLAY_VERSION=v2.2.0.3
ARG S6_OVERLAY_BASE_URL=https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}

# Set PS3NETSRV vars
ARG PS3NETSRV_REPO=https://github.com/aldostools/ps3netsrv.git
ARG PS3NETSRV_REF=master
ARG BUILD_FROM_GIT=false

ARG PS3NETSRV_VERSION=20260913
ARG PS3NETSRV_URL=https://github.com/aldostools/ps3netsrv/archive/refs/tags/${PS3NETSRV_VERSION}.tar.gz

# Set base images with s6 overlay download variable (necessary for multi-arch building via GitHub workflows)
FROM alpine:${ALPINE_VERSION} AS alpine-amd64

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-amd64.tar.gz"

FROM alpine:${ALPINE_VERSION} AS alpine-386

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-x86.tar.gz"

FROM alpine:${ALPINE_VERSION} AS alpine-armv6

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-armhf.tar.gz"

FROM alpine:${ALPINE_VERSION} AS alpine-armv7

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-arm.tar.gz"

FROM alpine:${ALPINE_VERSION} AS alpine-arm64

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-aarch64.tar.gz"

FROM alpine:${ALPINE_VERSION} AS alpine-ppc64le

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-ppc64le.tar.gz"

# Build ps3netsrv:master
FROM alpine:${ALPINE_VERSION} AS builder

ARG PS3NETSRV_REPO
ARG PS3NETSRV_REF
ARG PS3NETSRV_VERSION
ARG PS3NETSRV_URL
ARG BUILD_FROM_GIT

# Change working dir
WORKDIR /tmp

# Install deps and build binary
RUN \
  set -ex && \
  echo "Installing build dependencies..." && \
  apk add --update --no-cache \
    curl \
    git \
    build-base \
    meson \
    mbedtls-dev \
    musl \
    musl-dev \
    musl-dbg \
    musl-utils \
    tar

RUN \
  [ "${BUILD_FROM_GIT:-}" != "true" ] || (echo "Building ps3netsrv from git repo (ref: ${PS3NETSRV_REF})..." && \
    git clone --depth 1 "${PS3NETSRV_REPO}" --branch "${PS3NETSRV_REF}" repo && \
    cd /tmp/repo && \
    # Patch off64_t to off_t for Alpine 3.21+ \
    sed -i 's/\boff64_t\b/off_t/g' include/*.* && \
    sed -i 's/\boff64_t\b/off_t/g' src/*.* && \
    # meson does not define BUILD_DATE, so inject it the way upstream's Makefiles do \
    meson build --buildtype=release \
      -Dc_args=-DBUILD_DATE=\\\"$(date +%Y%m%d)\\\" \
      -Dcpp_args=-DBUILD_DATE=\\\"$(date +%Y%m%d)\\\" && \
    ninja -C build/ && \
    mkdir -p /tmp/ps3netsrv-bin && \
    cp -v /tmp/repo/build/ps3netsrv /tmp/ps3netsrv-bin/)

RUN \
  [ "${BUILD_FROM_GIT:-}" == "true" ] || (echo "Building ps3netsrv from release tag ${PS3NETSRV_VERSION}..." && \
    curl -sL --output /tmp/ps3netsrv.tar.gz "${PS3NETSRV_URL}" && \
    tar xzf /tmp/ps3netsrv.tar.gz -C /tmp && \
    cd /tmp/ps3netsrv-*/ && \
    # Patch off64_t to off_t for Alpine 3.21+ \
    sed -i 's/\boff64_t\b/off_t/g' include/*.* && \
    sed -i 's/\boff64_t\b/off_t/g' src/*.* && \
    # meson does not define BUILD_DATE, so inject it the way upstream's Makefiles do \
    meson build --buildtype=release \
      -Dc_args=-DBUILD_DATE=\\\"${PS3NETSRV_VERSION}\\\" \
      -Dcpp_args=-DBUILD_DATE=\\\"${PS3NETSRV_VERSION}\\\" && \
    ninja -C build/ && \
    mkdir -p /tmp/ps3netsrv-bin && \
    cp -v build/ps3netsrv /tmp/ps3netsrv-bin/)

# Runtime container
FROM alpine-${TARGETARCH:-amd64}${TARGETVARIANT}

# Download s6 overlay
ADD ${S6_OVERLAY_RELEASE} /tmp/s6overlay.tar.gz

# Copy binary from build container
COPY --from=builder /tmp/ps3netsrv-bin/ps3netsrv /usr/local/bin/ps3netsrv

# Install runtime deps and add users
RUN \
  set -ex && \
  echo "Installing runtime dependencies..." && \
  apk add --no-cache \
    bash \
    coreutils \
    shadow \
    tzdata \
    libstdc++ \
    musl \
    musl-utils \
    mbedtls && \
  echo "Extracting s6 overlay..." && \
    tar xzf /tmp/s6overlay.tar.gz -C / && \
  echo "Creating ps3netsrv user..." && \
    useradd -u 1000 -U -M -s /bin/false ps3netsrv && \
    usermod -G users ps3netsrv && \
    mkdir -p /var/log/ps3netsrv && \
    chown -R nobody:nogroup /var/log/ps3netsrv && \
  echo "Cleaning up temp directory..." && \
    rm -rf /tmp/*

# Add files
COPY rootfs/ /

ENV PS3NETSRV_PORT=38008 \
    PS3NETSRV_WHITELIST=

# Define mountable directories
VOLUME ["/games"]

# Expose ports
EXPOSE 38008

# Start s6
ENTRYPOINT ["/init"]

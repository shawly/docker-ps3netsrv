#
# ps3netsrv Dockerfile
#
# https://github.com/shawly/docker-ps3netsrv
#

# Set alpine version
ARG ALPINE_VERSION=3.18

# Set vars for s6 overlay
ARG S6_OVERLAY_VERSION=v2.2.0.3
ARG S6_OVERLAY_BASE_URL=https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}

# Set PS3NETSRV vars
ARG PS3NETSRV_REPO=https://github.com/aldostools/webMAN-MOD.git
ARG PS3NETSRV_DIR=_Projects_/ps3netsrv
ARG PS3NETSRV_REF=master
ARG BUILD_FROM_GIT=false

ARG PS3NETSRV_RELEASE=1.47.46
ARG PS3NETSRV_VERSION=20240709
ARG PS3NETSRV_URL=https://github.com/aldostools/webMAN-MOD/releases/download/${PS3NETSRV_RELEASE}/ps3netsrv_${PS3NETSRV_VERSION}.zip

# Set base images with s6 overlay download variable (necessary for multi-arch building via GitHub workflows)
FROM alpine:${ALPINE_VERSION} as alpine-amd64

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-amd64.tar.gz"

FROM alpine:${ALPINE_VERSION} as alpine-386

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-x86.tar.gz"

FROM alpine:${ALPINE_VERSION} as alpine-armv6

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-armhf.tar.gz"

FROM alpine:${ALPINE_VERSION} as alpine-armv7

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-arm.tar.gz"

FROM alpine:${ALPINE_VERSION} as alpine-arm64

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-aarch64.tar.gz"

FROM alpine:${ALPINE_VERSION} as alpine-ppc64le

ARG S6_OVERLAY_VERSION
ARG S6_OVERLAY_BASE_URL
ENV S6_OVERLAY_RELEASE="${S6_OVERLAY_BASE_URL}/s6-overlay-ppc64le.tar.gz"

# Build ps3netsrv:master
FROM alpine:${ALPINE_VERSION} as builder

ARG PS3NETSRV_REPO
ARG PS3NETSRV_DIR
ARG PS3NETSRV_REF
ARG PS3NETSRV_RELEASE
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
    tar \
    unzip

RUN \
  [ "${BUILD_FROM_GIT:-}" != "true" ] || (echo "Building ps3netsrv from git repo (ref: ${PS3NETSRV_REF})..." && \
    git clone --depth 1 "${PS3NETSRV_REPO}" --branch "${PS3NETSRV_REF}" repo && \
    cd /tmp/repo/${PS3NETSRV_DIR} && \
    meson build --buildtype=release && \
    ninja -C build/ && \
    mkdir -p /tmp/ps3netsrv-bin && \
    cp -v /tmp/repo/${PS3NETSRV_DIR}/build/ps3netsrv /tmp/ps3netsrv-bin/)

RUN \
  [ "${BUILD_FROM_GIT:-}" == "true" ] || (echo "Building ps3netsrv from release (ps3netsrv_${PS3NETSRV_VERSION}.zip)..." && \
    curl -sL --output /tmp/ps3netsrv.zip "${PS3NETSRV_URL}" && \
    unzip /tmp/ps3netsrv.zip -d /tmp && \
    find "/tmp" -type d -maxdepth 1 -iname "*ps3netsrv_*" -exec mv -f {} "/tmp/ps3netsrv" \; && \
    cd /tmp/ps3netsrv/ps3netsrv && \
    meson build --buildtype=release && \
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

#
# ps3netsrv Dockerfile
#
# https://github.com/shawly/docker-ps3netsrv
#

# Set alpine version
ARG ALPINE_VERSION=3.18

# Set vars for s6 overlay
ARG S6_OVERLAY_RELEASE=v3.1.6.2

# Set PS3NETSRV vars
ARG PS3NETSRV_REPO=https://github.com/aldostools/webMAN-MOD.git
ARG PS3NETSRV_SRC_DIR=_Projects_/ps3netsrv
ARG PS3NETSRV_SRC_REF=master
ARG BUILD_FROM_GIT=true

ARG PS3NETSRV_VERSION=20240210
ARG PS3NETSRV_GITHUB_API_URL=https://api.github.com/repos/aldostools/webMAN-MOD/releases

# Set base images with s6 overlay download variable (necessary for multi-arch building via GitHub workflows)
FROM alpine:${ALPINE_VERSION} as alpine-amd64

ARG S6_OVERLAY_RELEASE

# Add s6-overlay files
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-x86_64.tar.xz /tmp

FROM alpine:${ALPINE_VERSION} as alpine-386

ARG S6_OVERLAY_RELEASE

# Add s6-overlay files
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-i686.tar.xz /tmp

FROM alpine:${ALPINE_VERSION} as alpine-armv6

ARG S6_OVERLAY_RELEASE

# Add s6-overlay files
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-armhf.tar.xz /tmp

FROM alpine:${ALPINE_VERSION} as alpine-armv7

ARG S6_OVERLAY_RELEASE

# Add s6-overlay files
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-arm.tar.xz /tmp

FROM alpine:${ALPINE_VERSION} as alpine-arm64

ARG S6_OVERLAY_RELEASE

# Add s6-overlay files
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-noarch.tar.xz /tmp
ADD https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_RELEASE}/s6-overlay-aarch64.tar.xz /tmp

# Build ps3netsrv:master
FROM alpine:${ALPINE_VERSION} as builder

ARG PS3NETSRV_REPO
ARG PS3NETSRV_SRC_DIR
ARG PS3NETSRV_SRC_REF
ARG PS3NETSRV_GITHUB_API_URL
ARG PS3NETSRV_VERSION
ARG BUILD_FROM_GIT

# Change working dir
WORKDIR /tmp

# Install deps and build binary
RUN \
  set -e && \
  echo "Installing build dependencies..." && \
  apk add --update --no-cache \
    curl \
    jq \
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
  [ "${BUILD_FROM_GIT:-}" != "true" ] || (echo "Building ps3netsrv from git repo (ref: ${PS3NETSRV_SRC_REF:?})..." && \
    mkdir -p /tmp/repo/ && \
    cd /tmp/repo/ && \
    git init && \
    git remote add origin "${PS3NETSRV_REPO:?}" && \
    git fetch --depth 1 origin "${PS3NETSRV_SRC_REF:?}" && \
    git checkout FETCH_HEAD && \
    cd /tmp/repo/${PS3NETSRV_SRC_DIR:?} && \
    meson build --buildtype=release && \
    ninja -C build/ && \
    mkdir -p /tmp/ps3netsrv-bin && \
    cp -v /tmp/repo/${PS3NETSRV_SRC_DIR:?}/build/ps3netsrv /tmp/ps3netsrv-bin/)

RUN \
  [ "${BUILD_FROM_GIT:-}" == "true" ] || (echo "Building ps3netsrv from release (ps3netsrv_${PS3NETSRV_VERSION:?}.zip)..." && \
    cd /tmp && \
    echo "Getting releases from ${PS3NETSRV_GITHUB_API_URL:?}" && \
      curl -sL -o releases.json "${PS3NETSRV_GITHUB_API_URL:?}" && \
      PS3NETSRV_URL="$(jq -r --arg version "${PS3NETSRV_VERSION:?}" '[.[].assets[] | select(.name | startswith("ps3netsrv_" + $version)) | .browser_download_url] | first' releases.json)" && \
    echo "Downloading release from ${PS3NETSRV_URL:?}" && \
      curl -sL --output /tmp/ps3netsrv.zip "${PS3NETSRV_URL:?}" && \
    echo "Extracting release..." && \
      unzip /tmp/ps3netsrv.zip -d /tmp && \
      find "/tmp" -type d -maxdepth 1 -iname "*ps3netsrv_*" -exec mv -f {} "/tmp/ps3netsrv" \; && \
      cd /tmp/ps3netsrv/ps3netsrv && \
    echo "Building release..." && \
      meson build --buildtype=release && \
      ninja -C build/ && \
      mkdir -p /tmp/ps3netsrv-bin && \
      cp -v build/ps3netsrv /tmp/ps3netsrv-bin/)

# Runtime container
FROM alpine-${TARGETARCH:-amd64}${TARGETVARIANT}

# Copy binary from build container
COPY --from=builder /tmp/ps3netsrv-bin/ps3netsrv /usr/local/bin/ps3netsrv

# Install runtime deps and add users
RUN \
  set -e && \
  echo "Installing runtime dependencies..." && \
  apk add --no-cache \
    bash \
    coreutils \
    shadow \
    tzdata \
    libstdc++ \
    musl \
    musl-utils \
    mbedtls \
    xz && \
  echo "Extracting s6 overlay..." && \
    tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
  echo "Creating ps3netsrv user..." && \
    useradd -u 1000 -U -M -s /bin/false ps3netsrv && \
    usermod -G users ps3netsrv && \
    mkdir -p /var/log/ps3netsrv && \
    chown -R nobody:nogroup /var/log/ps3netsrv && \
  echo "Removing not needed packages" && \
    apk del --purge \
      xz && \
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

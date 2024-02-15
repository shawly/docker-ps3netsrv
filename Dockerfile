#
# ps3netsrv Dockerfile
#
# https://github.com/shawly/docker-ps3netsrv
#

# Set alpine version
ARG ALPINE_VERSION=3.11

# Set vars for s6 overlay
ARG S6_OVERLAY_VERSION=v1.22.1.0
ARG S6_OVERLAY_ARCH=amd64
ARG S6_OVERLAY_RELEASE=https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.gz

# Set PS3NETSRV vars
ARG PS3NETSRV_REPO=https://github.com/aldostools/webMAN-MOD.git
ARG PS3NETSRV_DIR=_Projects_/ps3netsrv
ARG PS3NETSRV_BRANCH=master

# Build ps3netsrv:master
FROM alpine:${ALPINE_VERSION} as builder

ARG PS3NETSRV_REPO
ARG PS3NETSRV_DIR
ARG PS3NETSRV_BRANCH

ENV PS3NETSRV_REPO=${PS3NETSRV_REPO} \
    PS3NETSRV_DIR=${PS3NETSRV_DIR} \
    PS3NETSRV_BRANCH=${PS3NETSRV_BRANCH} \
    PS3NETSRV_VERSION=20200611

# Change working dir.
WORKDIR /tmp

# Install deps and build binary.
RUN \
  set -ex && \
  echo "Installing build dependencies..." && \
  apk add --update --no-cache \
    git \
    build-base \
    meson \
    mbedtls-dev \
    tar && \
  echo "Building ps3netsrv..." && \
    git clone --depth 1 ${PS3NETSRV_REPO} repo && \
    cd /tmp/repo/${PS3NETSRV_DIR} && \
    git checkout ${PS3NETSRV_BRANCH} && \
    meson build --buildtype=release && \
    ninja -C build/ && \
    mkdir -p /tmp/ps3netsrv-bin && \
    cp -v /tmp/repo/${PS3NETSRV_DIR}/build/ps3netsrv /tmp/ps3netsrv-bin/

# Runtime container
FROM alpine:${ALPINE_VERSION}

ARG S6_OVERLAY_RELEASE
ENV S6_OVERLAY_RELEASE=${S6_OVERLAY_RELEASE}

# Download S6 Overlay
ADD ${S6_OVERLAY_RELEASE} /tmp/s6overlay.tar.gz

# Copy binary from build container.
COPY --from=builder /tmp/ps3netsrv-bin/ps3netsrv /usr/local/bin/ps3netsrv

# Install runtime deps and add users.
RUN \
  set -ex && \
  echo "Installing runtime dependencies..." && \
  apk add --no-cache \
    coreutils \
    shadow \
    tzdata \
    libstdc++ \
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

# Add files.
COPY rootfs/ /

# Define mountable directories.
VOLUME ["/games"]

# Expose ports.
EXPOSE 38008

# Metadata.
LABEL \
      org.label-schema.name="ps3netsrv" \
      org.label-schema.description="Docker container for ps3netsrv" \
      org.label-schema.version="1.4.5" \
      org.label-schema.vcs-url="https://github.com/shawly/docker-ps3netsrv" \
      org.label-schema.schema-version="1.0"

# Start s6.
ENTRYPOINT ["/init"]

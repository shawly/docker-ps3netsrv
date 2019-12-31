#
# ps3netsrv Dockerfile
#
# https://github.com/shawly/docker-ps3netsrv
#

# Set alpine version
ARG ALPINE_VERSION=3.10

# Set version for s6 overlay
ARG OVERLAY_VERSION="v1.22.1.0"
ARG OVERLAY_ARCH="amd64"

# Set PS3NETSRV version
ARG PS3NETSRV_REPO=https://github.com/aldostools/webMAN-MOD
ARG PS3NETSRV_DIR=_Projects_/ps3netsrv
ARG PS3NETSRV_BRANCH=master

# Build ps3netsrv:master
FROM alpine:${ALPINE_VERSION} as builder

ARG PS3NETSRV_REPO
ARG PS3NETSRV_DIR
ARG PS3NETSRV_BRANCH

ENV PS3NETSRV_REPO=${PS3NETSRV_REPO} \
    PS3NETSRV_DIR=${PS3NETSRV_DIR} \
    PS3NETSRV_BRANCH=${PS3NETSRV_BRANCH}

# Change working dir.
WORKDIR /tmp/repo

# Install deps and build binary.
RUN \
  echo "**** install build packages ****" && \
  apk add --update --no-cache \
    git \
    build-base \
    meson \
    mbedtls-dev \
    tar && \
  echo "**** build ps3netsrv ****" && \
  wget "${PS3NETSRV_REPO}/archive/${PS3NETSRV_BRANCH}.tar.gz" -O repo.tar.gz && \
  tar -xvf repo.tar.gz --strip 1 && \
  cd /tmp/repo/${PS3NETSRV_DIR} && \
  meson build --buildtype=release && \
  ninja -C build/

FROM alpine:${ALPINE_VERSION}

ARG OVERLAY_VERSION
ARG OVERLAY_ARCH
ARG PS3NETSRV_DIR

ENV OVERLAY_VERSION=${OVERLAY_VERSION} \
    OVERLAY_ARCH=${OVERLAY_ARCH} \
    PS3NETSRV_DIR=${PS3NETSRV_DIR}

# Copy binary from build container.
COPY --from=builder /tmp/repo/${PS3NETSRV_DIR}/build/ps3netsrv /usr/local/bin/ps3netsrv

# Install runtime deps and add users.
RUN \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
    bash \
    curl \
    ca-certificates \
    coreutils \
    shadow \
    tzdata \
    libstdc++ \
    mbedtls && \
  echo "**** add s6 overlay ****" && \
  curl -o /tmp/s6-overlay.tar.gz -L \
    "https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-${OVERLAY_ARCH}.tar.gz" && \
  tar xvzf /tmp/s6-overlay.tar.gz -C / && \
  echo "**** create abc user and make our folders ****" && \
  groupmod -g 1000 users && \
  useradd -u 911 -U -d /config -s /bin/false abc && \
  usermod -G users abc && \
  mkdir -p /var/log/ps3netsrv && \
  chown -R 65534:65534 /var/log/ps3netsrv && \
  echo "**** cleanup ****" && \
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
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/shawly/docker-ps3netsrv" \
      org.label-schema.schema-version="1.0"

# Start s6.
ENTRYPOINT ["/init"]

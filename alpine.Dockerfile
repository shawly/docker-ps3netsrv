#
# ps3netsrv Dockerfile (Alpine)
#
# https://github.com/shawly/docker-ps3netsrv
#
# The base image tags below are intentionally literal so Dependabot can bump
# them. Do not replace them with ARG interpolation, Dependabot cannot resolve
# ARG values in FROM instructions.
#

# Build ps3netsrv and stage the s6-overlay rootfs
FROM alpine:3.23 AS builder

# Upstream sources, see https://github.com/aldostools/ps3netsrv
ARG PS3NETSRV_REPO=https://github.com/aldostools/ps3netsrv.git
ARG PS3NETSRV_SRC_REF=master
ARG PS3NETSRV_VERSION
# Default to a master build so a plain `docker build` needs no arguments.
# The publish workflow passes BUILD_FROM_GIT=false plus a release tag.
ARG BUILD_FROM_GIT=true

ARG S6_OVERLAY_VERSION=v3.2.3.2
ARG S6_OVERLAY_DOWNLOAD_URL=https://github.com/just-containers/s6-overlay/releases/download

# Populated by buildx, used to pick the matching s6-overlay tarball
ARG TARGETARCH
ARG TARGETVARIANT

WORKDIR /tmp

RUN \
  set -eu && \
  echo "Installing build dependencies..." && \
  apk add --update --no-cache \
    build-base \
    curl \
    git \
    meson \
    musl-dev \
    tar \
    xz && \
  echo "Installing mbedTLS headers..." && \
    # 3.24 ships mbedTLS 4 as mbedtls-dev, ps3netsrv needs the 3.x headers
    { apk add --no-cache mbedtls3-dev 2>/dev/null || apk add --no-cache mbedtls-dev; }

RUN \
  set -eu && \
  if [ "${BUILD_FROM_GIT}" = "true" ]; then \
    echo "Building ps3netsrv from ${PS3NETSRV_REPO} (ref: ${PS3NETSRV_SRC_REF})..." && \
    git clone --depth 1 --branch "${PS3NETSRV_SRC_REF}" "${PS3NETSRV_REPO}" /tmp/src && \
    BUILD_DATE="$(date -u +%Y%m%d)"; \
  else \
    echo "Building ps3netsrv from release tag ${PS3NETSRV_VERSION:?}..." && \
    mkdir -p /tmp/src && \
    curl -fsSL "https://github.com/aldostools/ps3netsrv/archive/refs/tags/${PS3NETSRV_VERSION}.tar.gz" \
      | tar xz -C /tmp/src --strip-components=1 && \
    BUILD_DATE="${PS3NETSRV_VERSION}"; \
  fi && \
  cd /tmp/src && \
  echo "Patching off64_t to off_t for musl..." && \
    sed -i 's/\boff64_t\b/off_t/g' include/*.* src/*.* && \
  mkdir -p /tmp/ps3netsrv-bin && \
  echo "Forcing line buffered stdout so docker logs shows output promptly..." && \
    printf '\n// docker-ps3netsrv: stdout is a pipe under docker and the libc default of\n// full buffering hides the banner and every later message until the buffer\n// fills. A constructor runs before main and costs nothing.\nstatic void __attribute__((constructor)) ps3netsrv_line_buffer(void)\n{ setvbuf(stdout, NULL, _IOLBF, 0); }\n' >> src/main.cpp && \
    grep -q ps3netsrv_line_buffer src/main.cpp && \
  echo "Building mbedTLS flavour (meson, upstream's Linux reference build)..." && \
    meson build --buildtype=release \
      -Dc_args=-DBUILD_DATE=\\\"${BUILD_DATE}\\\" \
      -Dcpp_args=-DBUILD_DATE=\\\"${BUILD_DATE}\\\" && \
    ninja -C build/ && \
    cp -v build/ps3netsrv /tmp/ps3netsrv-bin/ps3netsrv-mbedtls && \
  echo "Building PolarSSL flavour (upstream Makefile.linux, bundled AES)..." && \
    make -f Makefile.linux BUILD_DATE="${BUILD_DATE}" && \
    cp -v ps3netsrv /tmp/ps3netsrv-bin/ps3netsrv-polarssl

# Unpack s6-overlay here so the runtime image needs neither curl nor xz
RUN \
  set -eu && \
  echo "Staging s6-overlay ${S6_OVERLAY_VERSION}..." && \
  case "${TARGETARCH:-amd64}${TARGETVARIANT:-}" in \
    amd64)  S6_ARCH=x86_64 ;; \
    386)    S6_ARCH=i486 ;; \
    arm64)  S6_ARCH=aarch64 ;; \
    armv7)  S6_ARCH=arm ;; \
    armv6)  S6_ARCH=armhf ;; \
    *)      echo "Unsupported platform: ${TARGETARCH:-}${TARGETVARIANT:-}" >&2; exit 1 ;; \
  esac && \
  mkdir -p /tmp/s6-root && \
  for tarball in noarch "${S6_ARCH}"; do \
    curl -fsSL "${S6_OVERLAY_DOWNLOAD_URL}/${S6_OVERLAY_VERSION}/s6-overlay-${tarball}.tar.xz" \
      | tar -C /tmp/s6-root -Jxp; \
  done

# Runtime container
FROM alpine:3.23

# Copy binaries and the s6-overlay rootfs from the build container
COPY --from=builder /tmp/ps3netsrv-bin/ps3netsrv-* /usr/bin/
COPY --from=builder /tmp/s6-root/ /

RUN \
  set -eu && \
  echo "Installing runtime dependencies..." && \
  apk add --no-cache \
    bash \
    coreutils \
    libstdc++ \
    shadow \
    tzdata && \
  echo "Installing mbedTLS runtime..." && \
    { apk add --no-cache mbedtls3 2>/dev/null || apk add --no-cache mbedtls; } && \
  echo "Creating ps3netsrv user..." && \
    useradd -u 1000 -U -M -s /bin/false ps3netsrv && \
    usermod -G users ps3netsrv && \
    mkdir -p /var/log/ps3netsrv && \
    chown -R nobody:nogroup /var/log/ps3netsrv

# Add files
COPY rootfs/ /

ENV PS3NETSRV_BINARY=mbedtls \
    PS3NETSRV_PORT=38008 \
    PS3NETSRV_WHITELIST=

# Define mountable directories
VOLUME ["/games"]

# Expose ports
EXPOSE 38008

# ps3netsrv listening on its port, and /games actually readable by it
HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
    CMD ["/usr/local/bin/ps3netsrv-healthcheck"]

# Start s6
ENTRYPOINT ["/init"]

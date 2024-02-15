#
# ps3netsrv Dockerfile
#
# https://github.com/shawly/docker-ps3netsrv
#

# Pull base image.
FROM jlesage/baseimage:alpine-3.9-glibc

# Define working directory.
WORKDIR /tmp

# Install dependencies
RUN apk add libstdc++ mbedtls

RUN ln -sf /usr/lib/libmbedcrypto.so.3 /lib64/libmbedcrypto.so.0

# Install ps3netsrv.
ADD ps3netsrv-builder/ps3netsrv.tar.gz /

# Add files.
COPY rootfs/ /

# Go to app dir
WORKDIR /opt/ps3netsrv

# Set environment variables.
ENV APP_NAME="ps3netsrv" \
    TAKE_CONFIG_OWNERSHIP="0"

# Define mountable directories.
VOLUME ["/games"]

# Expose ports.
EXPOSE 38008

# Metadata.
LABEL \
      org.label-schema.name="ps3netsrv" \
      org.label-schema.description="Docker container for ps3netsrv" \
      org.label-schema.version="1.1.1" \
      org.label-schema.vcs-url="https://github.com/shawly/docker-ps3netsrv" \
      org.label-schema.schema-version="1.0"

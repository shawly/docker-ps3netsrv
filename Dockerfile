#
# ps3netsrv Dockerfile
#
# https://github.com/shawly/docker-ps3netsrv
#

# Pull base image.
FROM jlesage/baseimage:alpine-3.6

# Define working directory.
WORKDIR /tmp

# Install PS3NetSvr.
ADD ps3netsrv-builder/ps3netsrv.tar.gz /

# Add files.
COPY rootfs/ /

# Set environment variables.
ENV APP_NAME="PS3NetSvr" \
    TAKE_CONFIG_OWNERSHIP="0"

# Define mountable directories.
VOLUME ["/games"]

# Expose ports.
EXPOSE 38008

# Metadata.
LABEL \
      org.label-schema.name="ps3netsrv" \
      org.label-schema.description="Docker container for PS3NetSvr" \
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/shawly/docker-ps3netsrv" \
      org.label-schema.schema-version="1.0"

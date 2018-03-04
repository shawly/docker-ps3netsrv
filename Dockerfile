#
# ps3netsrv Dockerfile
#
# https://github.com/shawly/docker-ps3netsrv
#

# Pull base image.
FROM jlesage/baseimage:debian-8

# Define working directory.
WORKDIR /tmp

# Install ps3netsrv.
ADD ps3netsrv-builder/ps3netsrv.tar.gz /

# Add files.
COPY rootfs/ /

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
      org.label-schema.version="unknown" \
      org.label-schema.vcs-url="https://github.com/shawly/docker-ps3netsrv" \
      org.label-schema.schema-version="1.0"

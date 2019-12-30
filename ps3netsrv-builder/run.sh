#!/bin/sh
SCRIPT_DIR="$(readlink -f "$(dirname "$0")")"
BUILDER_DOCKER_IMAGE=jlesage/baseimage:alpine-3.9-glibc

exec docker run --rm \
    -v "$SCRIPT_DIR:/output" \
    -v "$SCRIPT_DIR/builder:/builder:ro" \
    $BUILDER_DOCKER_IMAGE /builder/build.sh /output

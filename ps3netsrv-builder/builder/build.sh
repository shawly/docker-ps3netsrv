#!/bin/ash

SCRIPT_DIR="$(dirname "${basename $0}")"

# Validate script arguments.
if [ -z "$1" ]; then
    echo "ERROR: Output directory must be specified."
    exit 1
elif [ -n "$2" ] && [[ $2 != /* ]]; then
    echo "ERROR: Invalid root execution directory."
    exit 1
fi

TARBALL_DIR="$1"
ROOT_EXEC_DIR="${2:-/opt/ps3netsrv}"
BUILD_DIR=/tmp/ps3netsrv-build
INSTALL_BASEDIR=/tmp/ps3netsrv-install
INSTALL_DIR=$INSTALL_BASEDIR$ROOT_EXEC_DIR

mkdir -p "$TARBALL_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

echo "Installing build prerequisites..."
apk add --update alpine-sdk \
    mbedtls-dev \
    python3 \
    py-pip \
    py3-setuptools \
    ninja

pip3 install meson

#
# ps3netsrv
#
cd "$BUILD_DIR"
echo "Building ps3netsrv..."
cp -rv /builder/* $BUILD_DIR
meson buildrelease --buildtype=release
ninja -C buildrelease
chmod +x buildrelease/ps3netsrv
cp buildrelease/ps3netsrv $INSTALL_DIR

echo "Creating tarball..."
tar -zcf "$TARBALL_DIR/ps3netsrv.tar.gz" -C "$INSTALL_BASEDIR" "${ROOT_EXEC_DIR:1}" --owner=0 --group=0

echo "$TARBALL_DIR/ps3netsrv.tar.gz created successfully!"

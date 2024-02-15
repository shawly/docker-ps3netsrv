#!/bin/bash

set -e
set -o pipefail

export DEBIAN_FRONTEND=noninteractive

SCRIPT_DIR="$(dirname "${BASH_SOURCE[0]}")"

usage() {
    echo "usage: $(basename $0) OUTPUT_DIR [ROOT_EXEC_DIR]
  Arguments:
    OUTPUT_DIR     Directory where the tarball will be copied to.
    ROOT_EXEC_DIR  Root directory where ps3netsrv will be located at execution
                   time.  Default: '/opt/ps3netsrv'.
"
}

# Validate script arguments.
if [ -z "$1" ]; then
    echo "ERROR: Output directory must be specified."
    usage
    exit 1
elif [ -n "$2" ] && [[ $2 != /* ]]; then
    echo "ERROR: Invalid root execution directory."
    usage
    exit 1
fi

TARBALL_DIR="$1"
ROOT_EXEC_DIR="${2:-/opt/ps3netsvr}"
BUILD_DIR=/tmp/ps3netsvr-build
INSTALL_BASEDIR=/tmp/ps3netsvr-install
INSTALL_DIR=$INSTALL_BASEDIR$ROOT_EXEC_DIR

mkdir -p "$TARBALL_DIR"
mkdir -p "$BUILD_DIR"
mkdir -p "$INSTALL_DIR"

echo "Updating APT cache..."
apt-get update

echo "Installing build prerequisites..."
apt-get install -y \
    build-essential

#
# ps3netsrv
#
cd "$BUILD_DIR"
echo "Building ps3netsrv..."
cp -r /builder/* $BUILD_DIR
mv Makefile Makefile.win
mv Makefile.linux Makefile
make
chmod +x ps3netsrv
cp ps3netsrv $INSTALL_DIR

echo "Creating tarball..."
tar -zcf "$TARBALL_DIR/ps3netsrv.tar.gz" -C "$INSTALL_BASEDIR" "${ROOT_EXEC_DIR:1}" --owner=0 --group=0

echo "$TARBALL_DIR/ps3netsrv.tar.gz created successfully!"

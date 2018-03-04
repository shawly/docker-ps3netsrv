#!/bin/sh
# NOTE: Change the workdir to /games, as this is the default location when
#       opening files.
cd /games
exec /opt/ps3netsrv/ps3netsrv /games 2>&1 | tee /var/log/ps3netsrv.log
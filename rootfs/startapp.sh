#!/bin/sh
# NOTE: Change the workdir to /games, as this is the default location when
#       opening files.
cd /games
touch /var/log/ps3netsrv.log
exec /opt/ps3netsrv/ps3netsrv /games >> /var/log/ps3netsrv.log 2>&1
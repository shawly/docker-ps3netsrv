#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Take ownership of the log file.
touch /var/log/ps3netsrv.log
chown $USER_ID:$GROUP_ID /var/log/ps3netsrv.log

# vim: set ft=sh :

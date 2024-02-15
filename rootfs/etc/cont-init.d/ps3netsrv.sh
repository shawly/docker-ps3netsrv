#!/usr/bin/with-contenv sh

set -e # Exit immediately if a command exits with a non-zero status.
set -u # Treat unset variables as an error.

# Take ownership of the games directory content.
chown -R $USER_ID:$GROUP_ID /games >> /var/log/ps3netsrv.log 2>&1

# vim: set ft=sh :
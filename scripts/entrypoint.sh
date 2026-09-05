#!/bin/bash
set -e

# Ensure Transmission config dir exists and owns settings
mkdir -p /config
chown -R root:root /config /data

# Wait for Filer to be ready before starting Transmission (optional, but good practice)
# supervisord will start them together, the upload script will handle it when downloads finish.

exec /usr/bin/supervisord -c /etc/supervisord.conf

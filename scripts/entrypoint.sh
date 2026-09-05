#!/bin/bash
set -e

# Ensure Transmission config dir exists
mkdir -p /config /data/downloads /data/seaweedfs

# Start supervisord (manages both SeaweedFS + Transmission)
exec /usr/bin/supervisord -c /etc/supervisord.conf

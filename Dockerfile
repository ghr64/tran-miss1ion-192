FROM alpine:3.19

# --- OFFLINE BUILD: all dependencies are pre-baked ---
# No network needed during docker build.

# Install APK packages from local cache (no internet required)
COPY apk-cache/ /tmp/apk-cache/
RUN apk add --no-network --allow-untrusted --no-cache /tmp/apk-cache/*.apk && \
    rm -rf /tmp/apk-cache

# Install SeaweedFS from local binary
COPY bin/weed.tar.gz /tmp/weed.tar.gz
RUN tar -xzf /tmp/weed.tar.gz -C /usr/bin/ weed && \
    chmod +x /usr/bin/weed && \
    rm /tmp/weed.tar.gz

# Create directories
RUN mkdir -p /data/downloads /data/seaweedfs /config /var/log/supervisor /scripts

# Add configurations and scripts
COPY config/supervisord.conf /etc/supervisord.conf
COPY config/settings.json /config/settings.json
COPY scripts/entrypoint.sh /scripts/entrypoint.sh
COPY scripts/torrent-done.sh /scripts/torrent-done.sh

RUN chmod +x /scripts/entrypoint.sh /scripts/torrent-done.sh

# Ports:
# 9091: Transmission Web UI + RPC
# 51413/tcp+udp: Transmission Peer
# 8888: SeaweedFS Filer (file browser)
# 8000: SeaweedFS S3
# 9333: SeaweedFS Master UI
EXPOSE 9091 51413/tcp 51413/udp 8888 8000 9333

ENTRYPOINT ["/scripts/entrypoint.sh"]

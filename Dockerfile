FROM alpine:3.19

# Install Transmission, curl (for upload hook), supervisor (to run both services), and bash
RUN apk add --no-cache \
    transmission-daemon \
    transmission-cli \
    curl \
    supervisor \
    bash \
    jq

# Install SeaweedFS
ENV WEED_VERSION=3.70
RUN wget "https://github.com/seaweedfs/seaweedfs/releases/download/${WEED_VERSION}/linux_amd64.tar.gz" -O /tmp/weed.tar.gz && \
    tar -xzf /tmp/weed.tar.gz -C /usr/bin/ weed && \
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
# 9091: Transmission Web UI
# 51413/tcp, 51413/udp: Transmission Peer
# 8888: SeaweedFS Filer Web UI
# 8000: SeaweedFS S3
# 9333: SeaweedFS Master
# 8080: SeaweedFS Volume
EXPOSE 9091 51413/tcp 51413/udp 8888 8000 9333 8080

ENTRYPOINT ["/scripts/entrypoint.sh"]

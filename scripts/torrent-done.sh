#!/bin/bash
# torrent-done.sh — called by Transmission when a torrent finishes
# Env vars set by Transmission:
#   TR_TORRENT_DIR  — directory where files were downloaded
#   TR_TORRENT_NAME — torrent name (top-level file or folder)

FILER_URL="${SEAWEEDFS_FILER_URL:-http://localhost:8888}"
DEST_PATH="${SEAWEEDFS_DEST_PATH:-/downloads}"

SOURCE="${TR_TORRENT_DIR}/${TR_TORRENT_NAME}"

upload_file() {
    local file="$1"
    local rel_path="${file#${TR_TORRENT_DIR}/}"
    local remote_path="${DEST_PATH}/${rel_path}"
    local dir_path=$(dirname "$remote_path")

    echo "[torrent-done] Uploading: $file -> ${FILER_URL}${remote_path}"
    curl -s -X PUT \
        "${FILER_URL}${remote_path}" \
        -T "$file" \
        -o /dev/null \
        -w "%{http_code}"
}

if [ -f "$SOURCE" ]; then
    # Single file torrent
    status=$(upload_file "$SOURCE")
    if [ "$status" = "201" ] || [ "$status" = "200" ]; then
        echo "[torrent-done] Upload OK ($status), removing local: $SOURCE"
        rm -f "$SOURCE"
    else
        echo "[torrent-done] Upload FAILED (HTTP $status), keeping local: $SOURCE"
    fi
elif [ -d "$SOURCE" ]; then
    # Multi-file torrent — upload each file, preserve directory structure
    failed=0
    while IFS= read -r -d '' file; do
        status=$(upload_file "$file")
        if [ "$status" = "201" ] || [ "$status" = "200" ]; then
            echo "[torrent-done] Upload OK ($status): $file"
            rm -f "$file"
        else
            echo "[torrent-done] Upload FAILED (HTTP $status): $file"
            failed=1
        fi
    done < <(find "$SOURCE" -type f -print0)

    if [ "$failed" = "0" ]; then
        echo "[torrent-done] All files uploaded, removing dir: $SOURCE"
        rm -rf "$SOURCE"
    fi
else
    echo "[torrent-done] ERROR: source not found: $SOURCE"
    exit 1
fi

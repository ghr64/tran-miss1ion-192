#!/bin/bash
# torrent-done.sh — called by Transmission when a torrent finishes
# Env vars set by Transmission:
#   TR_TORRENT_DIR  — directory where files were downloaded
#   TR_TORRENT_NAME — torrent name (top-level file or folder)

FILER_URL="${SEAWEEDFS_FILER_URL:-http://localhost:8888}"
DEST_PATH="${SEAWEEDFS_DEST_PATH:-/downloads}"
MODE="${UPLOAD_MODE:-files}" # files, zip, tarzst

SOURCE="${TR_TORRENT_DIR}/${TR_TORRENT_NAME}"

# URL-encode a path (encode spaces and special chars, keep slashes)
urlencode_path() {
    python3 -c "
import sys, urllib.parse
parts = sys.argv[1].split('/')
print('/'.join(urllib.parse.quote(p, safe='') for p in parts))
" "$1"
}

upload_single_file() {
    local local_file="$1"
    local remote_name="$2"
    
    local remote_path="${DEST_PATH}/${remote_name}"
    local encoded_path
    encoded_path=$(urlencode_path "$remote_path")

    echo "[torrent-done] Uploading: $local_file -> ${FILER_URL}${encoded_path}"
    http_status=$(curl -s -o /dev/null -w "%{http_code}" \
        -X PUT \
        "${FILER_URL}${encoded_path}" \
        -T "$local_file")
    echo "[torrent-done] HTTP status: $http_status"
    echo "$http_status"
}

upload_tree() {
    local failed=0
    while IFS= read -r -d '' file; do
        local rel_path="${file#${TR_TORRENT_DIR}/}"
        status=$(upload_single_file "$file" "$rel_path")
        if [ "$status" = "201" ] || [ "$status" = "200" ]; then
            rm -f "$file"
        else
            echo "[torrent-done] Upload FAILED (HTTP $status): $file"
            failed=1
        fi
    done < <(find "$SOURCE" -type f -print0)

    if [ "$failed" = "0" ]; then
        echo "[torrent-done] All uploaded, removing dir: $SOURCE"
        rm -rf "$SOURCE"
    fi
}

pack_and_upload() {
    local ext="$1"
    local archive_path="/tmp/${TR_TORRENT_NAME}.${ext}"
    
    echo "[torrent-done] Packing to $archive_path"
    cd "$TR_TORRENT_DIR" || exit 1
    
    if [ "$ext" = "zip" ]; then
        zip -r -q "$archive_path" "$TR_TORRENT_NAME"
    elif [ "$ext" = "tar.zst" ]; then
        tar -c "$TR_TORRENT_NAME" | zstd -T0 -3 > "$archive_path"
    else
        echo "[torrent-done] Unknown archive format: $ext"
        return 1
    fi
    
    status=$(upload_single_file "$archive_path" "${TR_TORRENT_NAME}.${ext}")
    if [ "$status" = "201" ] || [ "$status" = "200" ]; then
        echo "[torrent-done] Archive upload OK, removing local files..."
        rm -rf "$SOURCE"
        rm -f "$archive_path"
    else
        echo "[torrent-done] Archive upload FAILED (HTTP $status), keeping local files."
    fi
}

if [ ! -e "$SOURCE" ]; then
    echo "[torrent-done] ERROR: source not found: $SOURCE"
    exit 1
fi

if [ -f "$SOURCE" ]; then
    # Single file torrents skip zipping
    status=$(upload_single_file "$SOURCE" "$TR_TORRENT_NAME")
    if [ "$status" = "201" ] || [ "$status" = "200" ]; then
        echo "[torrent-done] Upload OK, removing local: $SOURCE"
        rm -f "$SOURCE"
    else
        echo "[torrent-done] Upload FAILED (HTTP $status), keeping local: $SOURCE"
    fi
elif [ -d "$SOURCE" ]; then
    if [ "$MODE" = "zip" ]; then
        pack_and_upload "zip"
    elif [ "$MODE" = "tarzst" ]; then
        pack_and_upload "tar.zst"
    else
        upload_tree
    fi
fi

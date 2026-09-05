# tran-miss1ion-192

All-in-one Transmission + SeaweedFS container for Runflare.

Torrents download to temporary local space. Once complete, a script uploads them into the embedded SeaweedFS and deletes the local copy.

## Runflare NodePort Mapping
Expose these container ports on Runflare:
- `9091` -> Transmission Web UI (Default creds: `admin` / `admin`)
- `8888` -> SeaweedFS Filer Web UI (Browse your finished downloads here)
- `8000` -> SeaweedFS S3 API
- `51413` (TCP/UDP) -> Torrent peer connectivity (optional but recommended for speed)

## Build & Run
```bash
docker compose up -d --build
```

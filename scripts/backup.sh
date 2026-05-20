#!/usr/bin/env bash
# Daily backup: the keit database + the Odoo filestore.
# Locates the compose project relative to this script, so it runs from anywhere.
#
# Override defaults via env vars if needed:
#   BACKUP_DIR (default /var/backups/odoo)
#   BACKUP_DB  (default keit)
#   BACKUP_KEEP_DAYS (default 7)
set -euo pipefail

# repo root = parent of this script's directory (scripts/..)
cd "$(dirname "$(readlink -f "$0")")/.."

DEST="${BACKUP_DIR:-/var/backups/odoo}"
DB="${BACKUP_DB:-keit}"
KEEP_DAYS="${BACKUP_KEEP_DAYS:-7}"
STAMP="$(date +%F_%H%M)"
mkdir -p "$DEST"

echo "[$(date)] backup start (db=$DB)"

# 1. Database — custom format (compressed, supports selective restore)
docker compose exec -T db pg_dump -U odoo -Fc "$DB" > "$DEST/${DB}-${STAMP}.dump"

# 2. Filestore — attachments + generated documents (all DBs under data_dir)
docker compose exec -T odoo tar czf - -C /var/lib/odoo filestore > "$DEST/filestore-${STAMP}.tgz"

# 3. Rotate local copies (keep KEEP_DAYS)
find "$DEST" -type f -name '*.dump' -mtime "+${KEEP_DAYS}" -delete
find "$DEST" -type f -name '*.tgz'  -mtime "+${KEEP_DAYS}" -delete

# 4. OFF-VM COPY — REQUIRED for real safety. Uncomment + configure ONE:
#    (a) rclone to cloud / network storage (set up `rclone config` first):
# rclone copy "$DEST" keit-backup:odoo/ --include "*-${STAMP}.*"
#    (b) scp to another host:
# scp "$DEST"/*-"${STAMP}".* backupuser@backup-host:/backups/odoo/
#    (c) copy to a mounted KEIT network share:
# cp "$DEST"/*-"${STAMP}".* /mnt/keit-share/odoo-backups/

echo "[$(date)] backup done -> $DEST (local retention ${KEEP_DAYS}d)"
df -h "$DEST" | tail -1

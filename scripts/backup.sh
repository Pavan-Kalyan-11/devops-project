#!/bin/bash
# Shebang for Bash shell.

BACKUP_SRC="/var/www/html"   # Directory to backup (e.g., web application files).
BACKUP_DEST="/backup"        # Directory where backups will be stored.

# date +"%Y%m%d_%H%M%S": generate timestamp like 20251204_184500.
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Construct full backup file path with timestamp.
BACKUP_FILE="${BACKUP_DEST}/backup_${TIMESTAMP}.tar.gz"

# mkdir -p: create destination directory if it does not exist, no error if it already exists.
mkdir -p "$BACKUP_DEST"

# tar -czvf:
#   c: create archive
#   z: compress with gzip
#   v: verbose output (shows files being archived)
#   f: use given filename
# "$BACKUP_SRC": directory to archive.
tar -czvf "$BACKUP_FILE" "$BACKUP_SRC"

# Print confirmation message with backup location.
echo "Backup completed: $BACKUP_FILE"
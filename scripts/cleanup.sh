#!/bin/bash
# Shebang for Bash.

LOG_DIR="/var/log"  # Directory containing log files.
DAYS=30             # Number of days to keep logs; older logs will be deleted.

# find:
#   $LOG_DIR: base directory.
#   -type f: regular files only.
#   -name "*.log": only files ending with .log.
#   -mtime +$DAYS: files last modified more than $DAYS days ago.
#   -exec rm -f {} \;: for each matched file, execute 'rm -f' to delete it.
find "$LOG_DIR" -type f -name "*.log" -mtime +"$DAYS" -exec rm -f {} \;

# Print confirmation message.
echo "Deleted log files older than $DAYS days from $LOG_DIR"
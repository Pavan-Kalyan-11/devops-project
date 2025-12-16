#!/bin/bash
# Shebang for Bash.

SERVICE="nginx"  # Name of the service to monitor (as used by systemctl).

# systemctl is-active --quiet:
#   returns exit code 0 if service is active, non-zero if not.
# '!' negates the condition so the 'then' block runs when service is NOT active.
if ! systemctl is-active --quiet "$SERVICE"; then
  echo "$(date): $SERVICE is DOWN. Attempting restart..."
  systemctl restart "$SERVICE"  # Restart the service.

  # Optional: verify again and log status.
  if systemctl is-active --quiet "$SERVICE"; then
    echo "$(date): $SERVICE restart SUCCESS."
  else
    echo "$(date): $SERVICE restart FAILED. Manual intervention required."
  fi
else
  echo "$(date): $SERVICE is running."
fi
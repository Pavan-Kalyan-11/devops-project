#!/bin/bash
# Shebang for Bash.

URL="https://example.com"  # URL to monitor.

# curl options:
#   -o /dev/null: discard response body.
#   -s: silent mode (no progress output).
#   -w "%{http_code}": print only the HTTP status code.
STATUS=$(curl -o /dev/null -s -w "%{http_code}" "$URL")

# If status code is not 200, consider it as DOWN/issue.
if [ "$STATUS" -ne 200 ]; then
  echo "$(date): ALERT - $URL is DOWN (HTTP Status: $STATUS)"
  # Optional: integrate with mail, Slack, or AWS SNS for alerting.
  # mail -s "Site down" you@example.com <<< "$URL is down with status $STATUS"
else
  echo "$(date): OK - $URL is UP (HTTP Status: $STATUS)"
fi
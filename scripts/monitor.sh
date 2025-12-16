#!/bin/bash
# Shebang: tells the system to run this script with the Bash shell.

CPU_THRESHOLD=80   # Alert threshold for CPU usage in percentage.
MEM_THRESHOLD=80   # Alert threshold for memory usage in percentage.
DISK_THRESHOLD=80  # Alert threshold for disk usage in percentage.

# top -bn1: run 'top' in batch mode (-b) for 1 iteration (-n1).
# grep "Cpu(s)": filter the CPU summary line.
# awk '{print $2}': get the second column (approx user CPU usage).
# cut -d'.' -f1: remove the decimal part, keep integer only.
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'.' -f1)

# free: show memory usage.
# awk '/Mem/{...}': match the line starting with "Mem".
# $3/$2*100: used/total * 100 gives memory usage percentage.
# printf("%.0f"): print as integer (no decimals).
MEM_USAGE=$(free | awk '/Mem/{printf("%.0f"), $3/$2*100}')

# df -h /: show disk usage for root filesystem in human-readable form.
# awk 'NR==2 {print $5}': skip header (line 1), print 5th column (use%).
# sed 's/%//': remove the '%' symbol so we can compare as integer.
DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

# Check if CPU usage is greater than or equal to threshold.
if [ "$CPU_USAGE" -ge "$CPU_THRESHOLD" ]; then
  echo "WARNING: High CPU Usage - ${CPU_USAGE}%"
fi

# Check if memory usage is greater than or equal to threshold.
if [ "$MEM_USAGE" -ge "$MEM_THRESHOLD" ]; then
  echo "WARNING: High Memory Usage - ${MEM_USAGE}%"
fi

# Check if disk usage is greater than or equal to threshold.
if [ "$DISK_USAGE" -ge "$DISK_THRESHOLD" ]; then
  echo "WARNING: Low Disk Space - ${DISK_USAGE}% used"
fi
#!/bin/bash
# monitor-hardware.sh - Monitors hardware usage during performance tests

set -e

OUTPUT_FILE="${1:-logs/hardware-usage.log}"
INTERVAL="${2:-2}"  # Sample every 2 seconds by default
PID_FILE="logs/monitor.pid"

echo "Starting hardware monitoring (sampling every ${INTERVAL}s)..."
echo "Output: $OUTPUT_FILE"

# Create output file with header
{
    echo "========================================="
    echo "HARDWARE USAGE MONITORING"
    echo "========================================="
    echo "Started: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo "Sample Interval: ${INTERVAL}s"
    echo ""
} > "$OUTPUT_FILE"

# Function to clean up on exit
cleanup() {
    echo "" >> "$OUTPUT_FILE"
    echo "Monitoring stopped: $(date '+%Y-%m-%d %H:%M:%S %Z')" >> "$OUTPUT_FILE"
    rm -f "$PID_FILE"
    exit 0
}

trap cleanup SIGTERM SIGINT

# Store PID for later termination
echo $$ > "$PID_FILE"

# Monitoring loop
while true; do
    TIMESTAMP=$(date '+%H:%M:%S')
    
    {
        echo "--- Sample at $TIMESTAMP ---"
        
        # CPU Usage (overall)
        CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
        echo "CPU Usage: ${CPU_USAGE}%"
        
        # Memory Usage
        MEM_INFO=$(free -m | awk 'NR==2{printf "Memory: %s/%sMB (%.2f%%)", $3,$2,$3*100/$2 }')
        echo "$MEM_INFO"
        
        # Load Average
        LOAD_AVG=$(uptime | awk -F'load average:' '{print $2}')
        echo "Load Average:$LOAD_AVG"
        
        # Top processes by CPU (top 3)
        echo "Top CPU Processes:"
        ps aux --sort=-%cpu | awk 'NR<=4 {printf "  %-10s %5s%% %7s  %s\n", $1, $3, $4, $11}'
        
        # Disk I/O (if iostat available)
        if command -v iostat &> /dev/null; then
            DISK_STATS=$(iostat -x 1 2 | tail -n +4 | tail -1 | awk '{printf "Disk Util: %.1f%%", $NF}')
            echo "$DISK_STATS"
        fi
        
        echo ""
        
    } >> "$OUTPUT_FILE"
    
    sleep "$INTERVAL"
done

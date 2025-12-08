#!/bin/bash
# run-wrk-benchmark.sh - Runs wrk benchmarks against configured servers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

if ! command -v wrk &> /dev/null; then
    echo "Error: wrk is not installed"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed (required for JSON parsing)"
    exit 1
fi

# Read configuration
DURATION=$(jq -r '.wrk.duration' "$CONFIG_FILE")
THREADS=$(jq -r '.wrk.threads' "$CONFIG_FILE")
CONNECTIONS=$(jq -r '.wrk.connections' "$CONFIG_FILE")

echo "Running wrk benchmarks..."
echo "Configuration: Duration=$DURATION, Threads=$THREADS, Connections=$CONNECTIONS"
echo ""

# Get server names
SERVERS=$(jq -r '.servers | keys[]' "$CONFIG_FILE")

for SERVER in $SERVERS; do
    echo "========================================="
    echo "Benchmarking: $SERVER"
    echo "========================================="
    
    PORT=$(jq -r ".servers.$SERVER.port" "$CONFIG_FILE")
    NAME=$(jq -r ".servers.$SERVER.name" "$CONFIG_FILE")
    HEALTH_CHECK=$(jq -r ".servers.$SERVER.healthCheck" "$CONFIG_FILE")
    
    URL="http://localhost:$PORT$HEALTH_CHECK"
    
    echo "Target URL: $URL"
    echo "Checking if server is running..."
    
    # Wait for server to be ready (with timeout)
    MAX_ATTEMPTS=30
    ATTEMPT=0
    while ! curl -s -o /dev/null -w "%{http_code}" "$URL" | grep -q "200\|301\|302"; do
        ATTEMPT=$((ATTEMPT + 1))
        if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
            echo "Error: Server $SERVER (port $PORT) is not responding"
            continue 2
        fi
        echo "Waiting for server... (attempt $ATTEMPT/$MAX_ATTEMPTS)"
        sleep 2
    done
    
    echo "Server is ready. Starting benchmark..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_FILE="$PROJECT_ROOT/logs/wrk-$SERVER-$TIMESTAMP.txt"
    
    # Run wrk
    wrk -t"$THREADS" -c"$CONNECTIONS" -d"$DURATION" "$URL" > "$OUTPUT_FILE" 2>&1
    
    echo "Results saved to: $OUTPUT_FILE"
    echo ""
    
    # Display summary
    echo "Summary:"
    grep -E "Requests/sec|Latency|Transfer/sec" "$OUTPUT_FILE" || cat "$OUTPUT_FILE"
    echo ""
done

echo "wrk benchmarks completed!"

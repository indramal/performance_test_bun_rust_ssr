#!/bin/bash
# run-lighthouse.sh - Runs Lighthouse CI tests against configured servers

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Configuration file not found: $CONFIG_FILE"
    exit 1
fi

if ! command -v lhci &> /dev/null; then
    echo "Error: Lighthouse CI is not installed"
    echo "Install with: npm install -g @lhci/cli"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed (required for JSON parsing)"
    exit 1
fi

# Read configuration
RUNS=$(jq -r '.lighthouse.runs' "$CONFIG_FILE")
FORM_FACTOR=$(jq -r '.lighthouse.formFactor' "$CONFIG_FILE")
CHROME_FLAGS=$(jq -r '.lighthouse.chromeFlags' "$CONFIG_FILE")

echo "Running Lighthouse benchmarks..."
echo "Configuration: Runs=$RUNS, FormFactor=$FORM_FACTOR"
echo ""

# Get server names
SERVERS=$(jq -r '.servers | keys[]' "$CONFIG_FILE")

for SERVER in $SERVERS; do
    echo "========================================="
    echo "Lighthouse Test: $SERVER"
    echo "========================================="
    
    PORT=$(jq -r ".servers.$SERVER.port" "$CONFIG_FILE")
    NAME=$(jq -r ".servers.$SERVER.name" "$CONFIG_FILE")
    HEALTH_CHECK=$(jq -r ".servers.$SERVER.healthCheck" "$CONFIG_FILE")
    
    URL="http://localhost:$PORT$HEALTH_CHECK"
    
    echo "Target URL: $URL"
    echo "Checking if server is running..."
    
    # Wait for server to be ready
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
    
    echo "Server is ready. Starting Lighthouse test..."
    
    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    OUTPUT_DIR="$PROJECT_ROOT/logs"
    OUTPUT_JSON="$OUTPUT_DIR/lighthouse-$SERVER-$TIMESTAMP.json"
    OUTPUT_HTML="$OUTPUT_DIR/lighthouse-$SERVER-$TIMESTAMP.html"
    
    # Run Lighthouse
    lhci autorun \
        --collect.url="$URL" \
        --collect.numberOfRuns="$RUNS" \
        --collect.settings.formFactor="$FORM_FACTOR" \
        --collect.settings.chromeFlags="$CHROME_FLAGS" \
        --upload.target=filesystem \
        --upload.outputDir="$OUTPUT_DIR/.lighthouseci" \
        || echo "Lighthouse run failed for $SERVER"
    
    # Copy the latest report
    if [ -d "$OUTPUT_DIR/.lighthouseci" ]; then
        LATEST_JSON=$(find "$OUTPUT_DIR/.lighthouseci" -name "lhr-*.json" -type f -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2-)
        LATEST_HTML=$(find "$OUTPUT_DIR/.lighthouseci" -name "lhr-*.html" -type f -printf '%T@ %p\n' | sort -rn | head -1 | cut -d' ' -f2-)
        
        if [ -f "$LATEST_JSON" ]; then
            cp "$LATEST_JSON" "$OUTPUT_JSON"
            echo "JSON report saved to: $OUTPUT_JSON"
        fi
        
        if [ -f "$LATEST_HTML" ]; then
            cp "$LATEST_HTML" "$OUTPUT_HTML"
            echo "HTML report saved to: $OUTPUT_HTML"
        fi
        
        # Extract and display scores
        if [ -f "$OUTPUT_JSON" ]; then
            echo ""
            echo "Lighthouse Scores:"
            echo "  Performance:    $(jq -r '.categories.performance.score * 100' "$OUTPUT_JSON" 2>/dev/null || echo 'N/A')"
            echo "  Accessibility:  $(jq -r '.categories.accessibility.score * 100' "$OUTPUT_JSON" 2>/dev/null || echo 'N/A')"
            echo "  Best Practices: $(jq -r '.categories["best-practices"].score * 100' "$OUTPUT_JSON" 2>/dev/null || echo 'N/A')"
            echo "  SEO:            $(jq -r '.categories.seo.score * 100' "$OUTPUT_JSON" 2>/dev/null || echo 'N/A')"
        fi
    fi
    
    echo ""
done

echo "Lighthouse benchmarks completed!"

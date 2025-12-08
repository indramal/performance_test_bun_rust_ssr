#!/bin/bash
# generate-report.sh - Generates comprehensive markdown performance report

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/config.json"
LOGS_DIR="$PROJECT_ROOT/logs"
OUTPUT_FILE="$LOGS_DIR/benchmark-report.md"

echo "Generating performance report..."

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S %Z')
REPORT_DATE=$(date '+%Y%m%d_%H%M%S')

{
    echo "# Performance Benchmark Report"
    echo ""
    echo "**Generated:** $TIMESTAMP"
    echo ""
    
    echo "---"
    echo ""
    
    # System Information
    echo "## System Information"
    echo ""
    
    if [ -f "$LOGS_DIR/system-info.txt" ]; then
        echo '```'
        cat "$LOGS_DIR/system-info.txt"
        echo '```'
    else
        echo "*System information not available*"
    fi
    
    echo ""
    echo "---"
    echo ""
    
    # Test Configuration
    echo "## Test Configuration"
    echo ""
    
    if [ -f "$CONFIG_FILE" ]; then
        echo "### wrk Settings"
        echo ""
        echo "- **Duration:** $(jq -r '.wrk.duration' "$CONFIG_FILE")"
        echo "- **Threads:** $(jq -r '.wrk.threads' "$CONFIG_FILE")"
        echo "- **Connections:** $(jq -r '.wrk.connections' "$CONFIG_FILE")"
        echo ""
        
        echo "### Lighthouse Settings"
        echo ""
        echo "- **Runs:** $(jq -r '.lighthouse.runs' "$CONFIG_FILE")"
        echo "- **Form Factor:** $(jq -r '.lighthouse.formFactor' "$CONFIG_FILE")"
        echo ""
    fi
    
    echo "---"
    echo ""
    
    # wrk Benchmark Results
    echo "## wrk Benchmark Results"
    echo ""
    
    SERVERS=$(jq -r '.servers | keys[]' "$CONFIG_FILE" 2>/dev/null || echo "")
    
    if [ -n "$SERVERS" ]; then
        echo "| Server | Requests/sec | Avg Latency | Transfer/sec |"
        echo "|--------|--------------|-------------|--------------|"
        
        for SERVER in $SERVERS; do
            NAME=$(jq -r ".servers.$SERVER.name" "$CONFIG_FILE")
            
            # Find latest wrk result for this server
            LATEST_WRK=$(find "$LOGS_DIR" -name "wrk-$SERVER-*.txt" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
            
            if [ -f "$LATEST_WRK" ]; then
                REQ_SEC=$(grep "Requests/sec:" "$LATEST_WRK" | awk '{print $2}')
                LATENCY=$(grep "Latency" "$LATEST_WRK" | head -1 | awk '{print $2}')
                TRANSFER=$(grep "Transfer/sec:" "$LATEST_WRK" | awk '{print $2}')
                
                echo "| $NAME | ${REQ_SEC:-N/A} | ${LATENCY:-N/A} | ${TRANSFER:-N/A} |"
            else
                echo "| $NAME | N/A | N/A | N/A |"
            fi
        done
    else
        echo "*No benchmark results available*"
    fi
    
    echo ""
    echo "### Detailed Results"
    echo ""
    
    for SERVER in $SERVERS; do
        NAME=$(jq -r ".servers.$SERVER.name" "$CONFIG_FILE")
        LATEST_WRK=$(find "$LOGS_DIR" -name "wrk-$SERVER-*.txt" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
        
        if [ -f "$LATEST_WRK" ]; then
            echo "#### $NAME"
            echo ""
            echo '```'
            cat "$LATEST_WRK"
            echo '```'
            echo ""
        fi
    done
    
    echo "---"
    echo ""
    
    # Lighthouse Results
    echo "## Lighthouse Performance Scores"
    echo ""
    
    if [ -n "$SERVERS" ]; then
        echo "| Server | Performance | Accessibility | Best Practices | SEO |"
        echo "|--------|-------------|---------------|----------------|-----|"
        
        for SERVER in $SERVERS; do
            NAME=$(jq -r ".servers.$SERVER.name" "$CONFIG_FILE")
            
            # Find latest lighthouse result for this server
            LATEST_LH=$(find "$LOGS_DIR" -name "lighthouse-$SERVER-*.json" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
            
            if [ -f "$LATEST_LH" ]; then
                PERF=$(jq -r '.categories.performance.score * 100 | floor' "$LATEST_LH" 2>/dev/null || echo "N/A")
                ACCESS=$(jq -r '.categories.accessibility.score * 100 | floor' "$LATEST_LH" 2>/dev/null || echo "N/A")
                BP=$(jq -r '.categories["best-practices"].score * 100 | floor' "$LATEST_LH" 2>/dev/null || echo "N/A")
                SEO=$(jq -r '.categories.seo.score * 100 | floor' "$LATEST_LH" 2>/dev/null || echo "N/A")
                
                # Add score indicators
                PERF_IND=$([ "$PERF" != "N/A" ] && [ "$PERF" -ge 90 ] && echo "🟢" || ([ "$PERF" -ge 50 ] && echo "🟡" || echo "🔴"))
                ACCESS_IND=$([ "$ACCESS" != "N/A" ] && [ "$ACCESS" -ge 90 ] && echo "🟢" || ([ "$ACCESS" -ge 50 ] && echo "🟡" || echo "🔴"))
                BP_IND=$([ "$BP" != "N/A" ] && [ "$BP" -ge 90 ] && echo "🟢" || ([ "$BP" -ge 50 ] && echo "🟡" || echo "🔴"))
                SEO_IND=$([ "$SEO" != "N/A" ] && [ "$SEO" -ge 90 ] && echo "🟢" || ([ "$SEO" -ge 50 ] && echo "🟡" || echo "🔴"))
                
                echo "| $NAME | $PERF_IND ${PERF} | $ACCESS_IND ${ACCESS} | $BP_IND ${BP} | $SEO_IND ${SEO} |"
                
                # Store HTML report path for linking
                LATEST_HTML=$(find "$LOGS_DIR" -name "lighthouse-$SERVER-*.html" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
                if [ -f "$LATEST_HTML" ]; then
                    echo "<!-- HTML Report: $(basename "$LATEST_HTML") -->"
                fi
            else
                echo "| $NAME | N/A | N/A | N/A | N/A |"
            fi
        done
    else
        echo "*No Lighthouse results available*"
    fi
    
    echo ""
    echo "**Score Legend:** 🟢 Good (90+) | 🟡 Needs Improvement (50-89) | 🔴 Poor (<50)"
    echo ""
    
    echo "---"
    echo ""
    
    # Footer
    echo "## Notes"
    echo ""
    echo "- All tests were conducted on the system configuration listed above"
    echo "- Results may vary based on system load and network conditions"
    echo "- Lighthouse scores are based on $FORM_FACTOR form factor"
    echo ""
    
} > "$OUTPUT_FILE"

echo "Report generated: $OUTPUT_FILE"

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
    
    # Hardware Usage During Tests
    echo "## Hardware Usage During Tests"
    echo ""
    
    if [ -f "$LOGS_DIR/hardware-usage.log" ]; then
        echo "Real-time hardware monitoring was performed during the performance tests."
        echo ""
        
        # Calculate averages from the log
        echo "### Usage Summary"
        echo ""
        
        AVG_CPU=$(grep "CPU Usage:" "$LOGS_DIR/hardware-usage.log" | awk -F': ' '{sum+=$2; count++} END {if(count>0) printf "%.2f%%", sum/count; else print "N/A"}')
        MAX_CPU=$(grep "CPU Usage:" "$LOGS_DIR/hardware-usage.log" | awk -F': ' '{print $2}' | sort -rn | head -1)
        
        echo "- **Average CPU Usage:** $AVG_CPU"
        echo "- **Peak CPU Usage:** ${MAX_CPU:-N/A}"
        echo ""
        
        # Memory stats
        PEAK_MEM=$(grep "Memory:" "$LOGS_DIR/hardware-usage.log" | awk -F'[()]' '{print $2}' | sort -rn | head -1)
        echo "- **Peak Memory Usage:** ${PEAK_MEM:-N/A}"
        echo ""
        
        echo "### Detailed Monitoring Log"
        echo ""
        echo "<details>"
        echo "<summary>Click to expand full hardware usage log</summary>"
        echo ""
        echo '```'
        cat "$LOGS_DIR/hardware-usage.log"
        echo '```'
        echo ""
        echo "</details>"
        echo ""
    else
        echo "*Hardware usage monitoring data not available*"
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
        
        # Create a temporary file to store rows
        TEMP_ROWS=$(mktemp)
        
        for SERVER in $SERVERS; do
            NAME=$(jq -r ".servers.$SERVER.name" "$CONFIG_FILE")
            
            # Find latest wrk result for this server
            LATEST_WRK=$(find "$LOGS_DIR" -name "wrk-$SERVER-*.txt" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
            
            if [ -f "$LATEST_WRK" ]; then
                REQ_SEC=$(grep "Requests/sec:" "$LATEST_WRK" | awk '{print $2}')
                LATENCY=$(grep "Latency" "$LATEST_WRK" | head -1 | awk '{print $2}')
                TRANSFER=$(grep "Transfer/sec:" "$LATEST_WRK" | awk '{print $2}')
                
                # Use a sortable format for the first column (Requests/sec)
                # We'll strip the suffix for sorting, but keep the original for display
                # Actually, simpler to just output the row and sort by the 2nd column numerically
                echo "| $NAME | ${REQ_SEC:-N/A} | ${LATENCY:-N/A} | ${TRANSFER:-N/A} |" >> "$TEMP_ROWS"
            else
                echo "| $NAME | N/A | N/A | N/A |" >> "$TEMP_ROWS"
            fi
        done
        
        # Sort by Requests/sec (column 3 in the markdown table, but let's extract the number)
        # The format is "| Name | Req/Sec | ..."
        # We want to sort descending by Req/Sec.
        # sort -t'|' -k3 -rn handles this.
        cat "$TEMP_ROWS" | sort -t'|' -k3 -rn
        
        rm "$TEMP_ROWS"
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
    
    # Cache Performance Comparison
    echo "## Cache Performance Impact"
    echo ""
    
    # Find latest results for both bun servers
    LATEST_BUN=$(find "$LOGS_DIR" -name "wrk-bun_server-*.txt" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    LATEST_CACHE=$(find "$LOGS_DIR" -name "wrk-bun_server_cache-*.txt" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    
    if [ -f "$LATEST_BUN" ] && [ -f "$LATEST_CACHE" ]; then
        echo "Comparing **Bun Server** (no cache) vs **Bun Server (Cached)** with 2-day TTL:"
        echo ""
        
        # Extract metrics
        BUN_RPS=$(grep "Requests/sec:" "$LATEST_BUN" | awk '{print $2}')
        CACHE_RPS=$(grep "Requests/sec:" "$LATEST_CACHE" | awk '{print $2}')
        
        BUN_LAT=$(grep "Latency" "$LATEST_BUN" | head -1 | awk '{print $2}')
        CACHE_LAT=$(grep "Latency" "$LATEST_CACHE" | head -1 | awk '{print $2}')
        
        BUN_TRANSFER=$(grep "Transfer/sec:" "$LATEST_BUN" | awk '{print $2}')
        CACHE_TRANSFER=$(grep "Transfer/sec:" "$LATEST_CACHE" | awk '{print $2}')
        
        # Calculate improvements
        if [ -n "$BUN_RPS" ] && [ -n "$CACHE_RPS" ]; then
            RPS_IMPROVEMENT=$(awk "BEGIN {printf \"%.2f\", (($CACHE_RPS - $BUN_RPS) / $BUN_RPS) * 100}")
        else
            RPS_IMPROVEMENT="N/A"
        fi
        
        echo "| Metric | Without Cache | With Cache | Improvement |"
        echo "|--------|---------------|------------|-------------|"
        echo "| Requests/sec | ${BUN_RPS:-N/A} | ${CACHE_RPS:-N/A} | ${RPS_IMPROVEMENT}% |"
        echo "| Latency | ${BUN_LAT:-N/A} | ${CACHE_LAT:-N/A} | - |"
        echo "| Transfer/sec | ${BUN_TRANSFER:-N/A} | ${CACHE_TRANSFER:-N/A} | - |"
        echo ""
        
        # Performance analysis
        if [ "$RPS_IMPROVEMENT" != "N/A" ]; then
            PERF_FACTOR=$(awk "BEGIN {printf \"%.1f\", $CACHE_RPS / $BUN_RPS}")
            echo "> **Cache Hit Performance:** ${PERF_FACTOR}x faster than no-cache baseline"
            echo ""
            echo "The cached server eliminates React SSR rendering on cache hits, serving pre-rendered HTML directly from memory."
            echo ""
        fi
    else
        echo "*Cache comparison not available - both bun_server and bun_server_cache results needed*"
        echo ""
    fi
    
    echo "---"
    echo ""

    # Rust Framework Performance Comparison
    echo "## Rust Framework Performance Impact"
    echo ""
    
    # Find latest results for both rust servers
    LATEST_AXUM=$(find "$LOGS_DIR" -name "wrk-react_manifest_askama-*.txt" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    LATEST_ACTIX=$(find "$LOGS_DIR" -name "wrk-react_manifest_askama_actix-*.txt" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
    
    if [ -f "$LATEST_AXUM" ] && [ -f "$LATEST_ACTIX" ]; then
        echo "Comparing **Axum** vs **Actix Web** implementation of the same React SSR app:"
        echo ""
        
        # Extract metrics
        AXUM_RPS=$(grep "Requests/sec:" "$LATEST_AXUM" | awk '{print $2}')
        ACTIX_RPS=$(grep "Requests/sec:" "$LATEST_ACTIX" | awk '{print $2}')
        
        AXUM_LAT=$(grep "Latency" "$LATEST_AXUM" | head -1 | awk '{print $2}')
        ACTIX_LAT=$(grep "Latency" "$LATEST_ACTIX" | head -1 | awk '{print $2}')
        
        AXUM_TRANSFER=$(grep "Transfer/sec:" "$LATEST_AXUM" | awk '{print $2}')
        ACTIX_TRANSFER=$(grep "Transfer/sec:" "$LATEST_ACTIX" | awk '{print $2}')
        
        # Calculate difference
        if [ -n "$AXUM_RPS" ] && [ -n "$ACTIX_RPS" ]; then
            # Calculate percentage difference relative to Axum
            DIFF_RPS=$(awk "BEGIN {printf \"%.2f\", (($ACTIX_RPS - $AXUM_RPS) / $AXUM_RPS) * 100}")
            if (( $(echo "$DIFF_RPS > 0" | bc -l) )); then
                DIFF_STR="+${DIFF_RPS}% (Actix Faster)"
            else
                DIFF_STR="${DIFF_RPS}% (Axum Faster)"
            fi
        else
            DIFF_STR="N/A"
        fi
        
        echo "| Metric | Axum | Actix Web | Difference |"
        echo "|--------|------|-----------|------------|"
        echo "| Requests/sec | ${AXUM_RPS:-N/A} | ${ACTIX_RPS:-N/A} | ${DIFF_STR} |"
        echo "| Latency | ${AXUM_LAT:-N/A} | ${ACTIX_LAT:-N/A} | - |"
        echo "| Transfer/sec | ${AXUM_TRANSFER:-N/A} | ${ACTIX_TRANSFER:-N/A} | - |"
        echo ""
    else
        echo "*Rust framework comparison not available - both react_manifest_askama and react_manifest_askama_actix results needed*"
        echo ""
    fi
    
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

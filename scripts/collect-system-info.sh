#!/bin/bash
# collect-system-info.sh - Collects comprehensive system information for performance testing

set -e

OUTPUT_FILE="${1:-logs/system-info.txt}"

echo "Collecting system information..."

{
    echo "========================================="
    echo "SYSTEM INFORMATION REPORT"
    echo "========================================="
    echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S %Z')"
    echo ""
    
    echo "========================================="
    echo "OPERATING SYSTEM"
    echo "========================================="
    uname -a
    echo ""
    
    if [ -f /etc/os-release ]; then
        echo "Distribution Info:"
        cat /etc/os-release
        echo ""
    fi
    
    echo "========================================="
    echo "CPU INFORMATION"
    echo "========================================="
    lscpu | grep -E "Model name|Architecture|CPU\(s\)|Thread|Core|Socket|MHz"
    echo ""
    
    if [ -f /proc/cpuinfo ]; then
        echo "CPU Details:"
        grep "model name" /proc/cpuinfo | head -1
        echo "CPU Cores: $(grep -c "^processor" /proc/cpuinfo)"
        echo ""
    fi
    
    echo "========================================="
    echo "MEMORY INFORMATION"
    echo "========================================="
    free -h
    echo ""
    
    if [ -f /proc/meminfo ]; then
        echo "Memory Details:"
        grep -E "MemTotal|MemAvailable|SwapTotal" /proc/meminfo
        echo ""
    fi
    
    echo "========================================="
    echo "GPU INFORMATION"
    echo "========================================="
    if command -v lspci &> /dev/null; then
        lspci | grep -i "vga\|3d\|display" || echo "No GPU detected via lspci"
    else
        echo "lspci not available"
    fi
    echo ""
    
    if command -v nvidia-smi &> /dev/null; then
        echo "NVIDIA GPU Info:"
        nvidia-smi --query-gpu=name,driver_version,memory.total --format=csv,noheader || echo "nvidia-smi failed"
        echo ""
    fi
    
    echo "========================================="
    echo "DISK INFORMATION"
    echo "========================================="
    df -h / | tail -n +2
    echo ""
    
    echo "========================================="
    echo "NETWORK INFORMATION"
    echo "========================================="
    if command -v ip &> /dev/null; then
        ip addr show | grep -E "inet |link/ether" | head -10
    else
        ifconfig | grep -E "inet |ether" | head -10
    fi
    echo ""
    
    echo "========================================="
    echo "SOFTWARE VERSIONS"
    echo "========================================="
    
    if command -v node &> /dev/null; then
        echo "Node.js: $(node --version)"
    else
        echo "Node.js: Not installed"
    fi
    
    if command -v npm &> /dev/null; then
        echo "npm: $(npm --version)"
    else
        echo "npm: Not installed"
    fi
    
    if command -v bun &> /dev/null; then
        echo "Bun: $(bun --version)"
    else
        echo "Bun: Not installed"
    fi
    
    if command -v rustc &> /dev/null; then
        echo "Rust: $(rustc --version)"
    else
        echo "Rust: Not installed"
    fi
    
    if command -v cargo &> /dev/null; then
        echo "Cargo: $(cargo --version)"
    else
        echo "Cargo: Not installed"
    fi
    
    if command -v wrk &> /dev/null; then
        echo "wrk: $(wrk --version 2>&1 | head -1)"
    else
        echo "wrk: Not installed"
    fi
    
    if command -v lhci &> /dev/null; then
        echo "Lighthouse CI: $(lhci --version)"
    else
        echo "Lighthouse CI: Not installed"
    fi
    
    echo ""
    echo "========================================="
    echo "SYSTEM LOAD"
    echo "========================================="
    uptime
    echo ""
    
} > "$OUTPUT_FILE"

echo "System information collected: $OUTPUT_FILE"

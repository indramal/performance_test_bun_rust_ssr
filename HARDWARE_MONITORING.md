# Real-Time Hardware Monitoring During Performance Tests

This document explains how hardware usage is monitored during performance tests.

## Overview

The performance testing infrastructure includes **real-time hardware monitoring** that runs continuously during wrk and Lighthouse tests. This provides insights into how the servers consume system resources under load.

## What is Monitored

### Metrics Collected

- **CPU Usage** (overall system percentage)
- **Memory Usage** (used/total and percentage)
- **Load Average** (1min, 5min, 15min)
- **Top CPU Processes** (top 3 processes by CPU usage)
- **Disk I/O Utilization** (if `iostat` is available)

### Sampling Rate

- Default: Every **2 seconds**
- Customizable via script parameter

## How It Works

### 1. Monitoring Script

The [`scripts/monitor-hardware.sh`](file:///home/ihackerubuntu/ProjectFiles/Rust_Test/test_ssr/last_check_ssr/scripts/monitor-hardware.sh) script:

- Runs in the background during performance tests
- Samples system metrics at regular intervals
- Writes timestamped data to `logs/hardware-usage.log`
- Terminates automatically when tests complete

### 2. GitHub Actions Integration

The workflow:

1. **Starts monitoring** before running wrk benchmarks
2. **Continues monitoring** through Lighthouse tests
3. **Stops monitoring** after all tests complete
4. **Includes stats** in the generated report

### 3. Report Integration

The [`scripts/generate-report.sh`](file:///home/ihackerubuntu/ProjectFiles/Rust_Test/test_ssr/last_check_ssr/scripts/generate-report.sh) processes the monitoring log to show:

- **Average CPU Usage** across all samples
- **Peak CPU Usage** during tests
- **Peak Memory Usage** during tests
- **Full monitoring log** (collapsible section)

## Usage

### Local Testing

```bash
# Start monitoring in background
bash scripts/monitor-hardware.sh &
MONITOR_PID=$!

# Run your performance tests
bash scripts/run-wrk-benchmark.sh
bash scripts/run-lighthouse.sh

# Stop monitoring
kill $MONITOR_PID

# Generate report (includes hardware stats)
bash scripts/generate-report.sh
```

### GitHub Actions

Hardware monitoring is automatically included in the workflow. No manual intervention needed.

## Output Format

### Sample Log Entry

```
--- Sample at 13:05:42 ---
CPU Usage: 45.2%
Memory: 3250/11264MB (28.86%)
Load Average: 2.45, 1.83, 1.21
Top CPU Processes:
  USER       %CPU   %MEM  COMMAND
  root       42.3%  1.2%  wrk
  bun        18.5%  5.4%  bun
  rust       12.1%  3.2%  react_server
```

### Report Summary

The report shows:

```markdown
## Hardware Usage During Tests

- **Average CPU Usage:** 38.45%
- **Peak CPU Usage:** 52.3%
- **Peak Memory Usage:** 32.15%
```

## Benefits

1. **Performance Context**: Understand if servers are CPU-bound, memory-bound, or I/O-bound
2. **Resource Planning**: Determine appropriate server sizing
3. **Bottleneck Identification**: See which processes consume most resources
4. **Trend Analysis**: Compare resource usage across different test runs

## Customization

### Change Sampling Interval

```bash
# Sample every 5 seconds instead of 2
bash scripts/monitor-hardware.sh logs/hardware-usage.log 5
```

### Add Custom Metrics

Edit [`scripts/monitor-hardware.sh`](file:///home/ihackerubuntu/ProjectFiles/Rust_Test/test_ssr/last_check_ssr/scripts/monitor-hardware.sh) to include additional metrics like:

- Network traffic (`ifstat`, `iftop`)
- GPU usage (`nvidia-smi`)
- Process-specific metrics (`pidstat`)

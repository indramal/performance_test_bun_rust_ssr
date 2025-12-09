# Performance Testing Infrastructure

This repository contains performance testing infrastructure for benchmarking two server implementations:
- **Bun Server** - A TypeScript/Bun-based React SSR server
- **React Server** - A Rust/Axum-based React SSR server
- **React Manifest Askama** - A Rust/Axum-based React SSR server with Askama templating
- **React Manifest Askama Actix** - A Rust/Actix-based React SSR server with Askama templating

## 🚀 Quick Start

### Local Testing

1. **Install Dependencies**
   ```bash
   # Install wrk (HTTP benchmarking tool)
   sudo apt-get install wrk
   
   # Install jq (JSON processor)
   sudo apt-get install jq
   
   # Install Lighthouse CI
   npm install -g @lhci/cli
   ```

2. **Make Scripts Executable**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Build and Start Servers**
   
   For Bun Server:
   ```bash
   cd bun_server
   bun install
   bun run build
   bun run start
   ```
   
   For React Server:
   ```bash
   cd react_server
   cd frontend && npm install && npm run build && cd ..
   cargo build --release
   cargo run --release
   ```

4. **Run Performance Tests**
   ```bash
   # Collect system information
   bash scripts/collect-system-info.sh
   
   # Run wrk benchmarks
   bash scripts/run-wrk-benchmark.sh
   
   # Run Lighthouse tests
   bash scripts/run-lighthouse.sh
   
   # Generate comprehensive report
   bash scripts/generate-report.sh
   ```

5. **View Results**
   ```bash
   cat logs/benchmark-report.md
   ```

### GitHub Actions (Automated Testing)

Performance tests can be triggered manually via GitHub Actions:

1. Go to **Actions** tab in GitHub
2. Select **Performance Testing** workflow
3. Click **Run workflow**
4. Wait for completion
5. View generated report in `report/` folder

The workflow will automatically:
- Collect system information
- Build both servers
- Run wrk benchmarks
- Run Lighthouse tests
- Generate a comprehensive report
- Commit the report to the repository

## 📁 Directory Structure

```
.
├── .github/
│   └── workflows/
│       └── performance-test.yml    # GitHub Actions workflow
├── config/
│   └── config.json                 # Configuration for servers and tests
├── scripts/
│   ├── collect-system-info.sh      # System info collection
│   ├── run-wrk-benchmark.sh        # wrk HTTP benchmarking
│   ├── run-lighthouse.sh           # Lighthouse performance testing
│   └── generate-report.sh          # Report generation
├── logs/                           # Test outputs (gitignored except .gitkeep)
│   └── .gitkeep
├── report/                         # Committed performance reports
│   └── .gitkeep
├── bun_server/                     # Bun-based server implementation
└── react_server/                   # Rust-based server implementation
```

## ⚙️ Configuration

Edit `config/config.json` to customize:

### Server Settings
- Port numbers
- Health check endpoints
- Build and start commands

### wrk Settings
- Duration (default: 30s)
- Threads (default: 4)
- Connections (default: 100)

### Lighthouse Settings
- Number of runs (default: 3)
- Form factor (default: desktop)
- Chrome flags

## 📊 Reports

Generated reports include:

### System Information
- OS details
- CPU specifications
- RAM capacity
- GPU information
- Disk space
- Software versions (Node.js, Bun, Rust, etc.)

### wrk Benchmark Results
- Requests per second
- Average latency
- Transfer rate per second
- Detailed statistics

### Lighthouse Scores
- Performance score
- Accessibility score
- Best practices score
- SEO score

Reports are saved with timestamps:
- Local: `logs/benchmark-report.md`
- GitHub Actions: `report/benchmark-YYYYMMDD_HHMMSS.md`

## 🔧 Troubleshooting

### Servers Not Starting
```bash
# Check if ports are in use
lsof -i :3000
lsof -i :8080

# Stop any conflicting processes
kill <PID>
```

### wrk Not Found
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install wrk

# macOS
brew install wrk
```

### Lighthouse CI Not Found
```bash
npm install -g @lhci/cli
```

## 📝 Notes

- All tests are run against `localhost`
- Default ports: Bun Server (3000), React Server (3001), Bun Server Cached (3002), React Manifest Askama (3003), React Manifest Askama Actix (3004)
- Reports include color-coded Lighthouse scores
- GitHub Actions automatically cleans up logs after committing reports

## 🤝 Contributing

To add more servers or modify test configurations:

1. Update `config/config.json` with new server details
2. Ensure server has health check endpoint
3. Update GitHub Actions workflow if additional setup is needed
4. Test locally before relying on automated workflow

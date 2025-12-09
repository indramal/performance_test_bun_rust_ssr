# React Manifest Askama

A modern web application combining **Vite + React CSR** with **Axum + Askama** for optimal performance and developer experience.

## 🏗️ Architecture

This project uses:
- **Vite** - Fast build tool that generates a manifest.json mapping
- **React 19** - Client-side rendering (CSR) only
- **TanStack Router** - Client-side routing
- **TanStack Query** - Data fetching with server hydration support
- **Axum** - High-performance Rust web server
- **Askama** - Type-safe Rust templates

**Key Concept**: Axum serves HTML shells via Askama templates. React mounts client-side and takes over navigation. No SSR complexity!

## 🚀 Quick Start

### Prerequisites
- Rust toolchain (2021 edition)
- Node.js or Bun

### Development Workflow

**Option 1: Full Development Stack**
```bash
# Terminal 1: React development server (HMR enabled)
cd client
npm install
npm run dev
# Opens on http://localhost:5173

# Terminal 2: Axum server (requires build first)
cd client && npm run build && cd ..
cargo run
# Opens on http://localhost:3100
```

**Option 2: Production Build**
```bash
# Build React client
cd client
npm install
npm run build

# Run Axum server
cd ..
cargo run --release
# Opens on http://localhost:3100
```

## 📁 Project Structure

```
react_manifest_askama/
├── Cargo.toml              # Rust dependencies
├── src/
│   └── main.rs             # Axum server with manifest loading
├── templates/
│   └── layout.html         # Askama HTML template
├── client/                 # React application
│   ├── package.json
│   ├── vite.config.js      # Vite config with manifest: true
│   ├── index.html          # Dev-only
│   └── src/
│       ├── main.jsx        # React entry point
│       ├── router.jsx      # TanStack Router setup
│       └── pages/
│           ├── Home.jsx
│           └── About.jsx
└── dist/                   # Vite build output (gitignored)
    ├── manifest.json       # Asset hash mapping
    └── assets/             # Hashed JS/CSS files
```

## 🔧 How It Works

### 1. Build Process
Vite builds the React app and generates `dist/manifest.json`:
```json
{
  "src/main.jsx": {
    "file": "assets/main-abc123.js",
    "css": ["assets/main-def456.css"]
  }
}
```

### 2. Server Startup
Axum reads `manifest.json` and extracts asset URLs.

### 3. Request Handling
For each route (`/`, `/about`, etc.):
1. Axum determines the page title and meta tags
2. Renders the Askama template with:
   - `{{ title }}` - Dynamic page title
   - `{{ js }}` - Hashed JS bundle URL
   - `{{ css }}` - Hashed CSS URL (optional)
   - `{{ initial_data }}` - Server data as `window.__INITIAL_DATA__`

### 4. Client Rendering
1. Browser receives HTML shell
2. Loads JavaScript bundle
3. React mounts to `<div id="root"></div>`
4. TanStack Router handles navigation
5. TanStack Query fetches data (or uses `window.__INITIAL_DATA__`)

## ✨ Features

### SEO-Friendly Per-Route Meta Tags
Edit `main.rs` in the `handle_page` function:
```rust
let (title, meta_desc) = match route.as_str() {
    "" | "/" => ("Home - My Site", "Home description"),
    "about" => ("About - My Site", "About description"),
    "products" => ("Products - My Site", "Products description"),
    _ => ("My Site", "Default description"),
};
```

### Server-Side Data Injection
Inject data for TanStack Query hydration:
```rust
// In main.rs handle_page function
#[derive(Serialize)]
struct InitData {
    user: User,
    config: Config,
}
let initial_data_json = serde_json::to_string(&my_data).ok();
```

Client-side (automatic):
```jsx
// In Home.jsx
const { data } = useQuery({
  queryKey: ['homeData'],
  queryFn: fetchFromAPI,
  initialData: window.__INITIAL_DATA__, // Uses server data!
});
```

### Adding New Routes

**1. Add React Route**
```jsx
// client/src/router.jsx
const newRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/new-page',
  component: NewPage,
});

const routeTree = rootRoute.addChildren([
  indexRoute, 
  aboutRoute, 
  newRoute // Add here
]);
```

**2. Add Server Title Logic**
```rust
// src/main.rs
let (title, meta_desc) = match route.as_str() {
    // ... existing routes
    "new-page" => ("New Page - My Site", "New page description"),
    // ...
};
```

## 🔍 Development Tips

### Vite Dev Server
Use `npm run dev` in the `client/` folder for:
- ⚡ Lightning-fast Hot Module Replacement (HMR)
- 🔄 Instant React component updates
- 🐛 Better error messages

**Note**: This bypasses Axum, so you won't see server-injected data or dynamic titles.

### Production Testing
Always test the full stack:
```bash
cd client && npm run build && cd ..
cargo run
```

### Debugging Manifest Issues
Check if manifest is generated:
```bash
cat dist/manifest.json | jq
```

Verify the entry key matches `vite.config.js`:
```js
rollupOptions: {
  input: '/src/main.jsx'  // Must match manifest key!
}
```

## 📦 Deployment

### Build for Production
```bash
cd client
npm run build
cd ..
cargo build --release
```

### Run in Production
```bash
./target/release/react_manifest_askama
```

Server runs on `0.0.0.0:3100` by default. Change in `main.rs`:
```rust
let listener = tokio::net::TcpListener::bind("0.0.0.0:YOUR_PORT").await.unwrap();
```

## 🎯 Performance Benefits

- **No SSR Overhead**: React only runs in the browser
- **Rust Speed**: Axum serves static assets blazingly fast
- **Smart Caching**: Hashed asset filenames enable aggressive caching
- **Type Safety**: Askama templates are compile-time checked
- **Minimal Bundle**: Only ships what you need

## 🛠️ Troubleshooting

**Problem**: `manifest.json not found`
```
Solution: Run `cd client && npm run build` before `cargo run`
```

**Problem**: Assets return 404
```
Check: dist/assets/ directory exists and contains .js/.css files
Verify: Axum ServeDir path points to "dist/assets"
```

**Problem**: Wrong title shows in browser
```
Check: Route path in Axum matches your URL
Hard refresh: Browser may cache old HTML
```

**Problem**: React not mounting
```
Check: Browser console for JavaScript errors
Verify: <div id="root"></div> exists in HTML source
Ensure: manifest.json has correct .js file path
```

## 📄 License

This is a template project - use it however you like!

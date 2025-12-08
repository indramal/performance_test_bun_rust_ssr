use axum::{
    extract::Path,
    response::{Html, IntoResponse, Json},
    routing::get,
    Router,
};
use serde_json::{json, Value};
use std::net::SocketAddr;
use std::sync::Once;
use tower_http::services::ServeDir;

static V8_INIT: Once = Once::new();

fn init_v8() {
    V8_INIT.call_once(|| {
        let platform = v8::new_default_platform(0, false).make_shared();
        v8::V8::initialize_platform(platform);
        v8::V8::initialize();
    });
}

#[tokio::main]
async fn main() {
    // Initialize V8 platform
    init_v8();

    // Build our application with routes
    let app = Router::new()
        // API routes
        .route("/api/hello", get(api_hello).put(api_hello_put))
        .route("/api/hello/:name", get(api_hello_name))
        // Static assets
        .nest_service("/assets", ServeDir::new("dist/client/assets"))
        .nest_service("/logo.svg", ServeDir::new("frontend/public/logo.svg"))
        .nest_service("/react.svg", ServeDir::new("frontend/public/react.svg"))
        // SSR fallback for all other routes
        .fallback(ssr_handler);

    // Run the server
    let addr = SocketAddr::from(([0, 0, 0, 0], 8080));
    println!("🚀 Server running at http://{}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}

// API Handlers
async fn api_hello() -> Json<Value> {
    Json(json!({
        "message": "Hello, world!",
        "method": "GET"
    }))
}

async fn api_hello_put() -> Json<Value> {
    Json(json!({
        "message": "Hello, world!",
        "method": "PUT"
    }))
}

async fn api_hello_name(Path(name): Path<String>) -> Json<Value> {
    Json(json!({
        "message": format!("Hello, {}!", name)
    }))
}

// Polyfills for V8 context (React needs some globals)
const V8_POLYFILLS: &str = r#"
var globalThis = this;
var global = this;
var self = this;
var window = this;

// Console polyfill
var console = {
    log: function() {},
    warn: function() {},
    error: function() {},
    info: function() {},
    debug: function() {}
};

// Minimal process polyfill
var process = {
    env: { NODE_ENV: 'production' },
    version: 'v18.0.0',
    nextTick: function(fn) { fn(); }
};

// Minimal setTimeout/clearTimeout
var setTimeout = function(fn, ms) { fn(); return 0; };
var clearTimeout = function(id) {};
var setInterval = function(fn, ms) { return 0; };
var clearInterval = function(id) {};

// MessageChannel polyfill (React scheduler needs this)
var MessageChannel = function() {
    var self = this;
    this.port1 = {
        onmessage: null,
        postMessage: function(msg) {
            if (self.port2.onmessage) {
                self.port2.onmessage({ data: msg });
            }
        }
    };
    this.port2 = {
        onmessage: null,
        postMessage: function(msg) {
            if (self.port1.onmessage) {
                self.port1.onmessage({ data: msg });
            }
        }
    };
};

// TextEncoder/TextDecoder polyfills (minimal)
var TextEncoder = function() {};
TextEncoder.prototype.encode = function(str) {
    var arr = [];
    for (var i = 0; i < str.length; i++) {
        arr.push(str.charCodeAt(i));
    }
    return new Uint8Array(arr);
};

var TextDecoder = function() {};
TextDecoder.prototype.decode = function(arr) {
    return String.fromCharCode.apply(null, arr);
};

// URL polyfill (minimal)
if (typeof URL === 'undefined') {
    var URL = function(url, base) {
        this.href = url;
        this.pathname = url;
        this.origin = '';
    };
}

// location polyfill
var location = {
    href: 'http://localhost:8080/',
    origin: 'http://localhost:8080',
    protocol: 'http:',
    host: 'localhost:8080',
    hostname: 'localhost',
    port: '8080',
    pathname: '/',
    search: '',
    hash: ''
};
"#;

// Execute JavaScript with V8 directly
fn execute_js(js_code: &str) -> Result<String, String> {
    let isolate = &mut v8::Isolate::new(v8::CreateParams::default());
    let handle_scope = &mut v8::HandleScope::new(isolate);
    let context = v8::Context::new(handle_scope, Default::default());
    let scope = &mut v8::ContextScope::new(handle_scope, context);

    // Create a TryCatch to get detailed error messages
    let try_catch = &mut v8::TryCatch::new(scope);

    // Run polyfills first
    let polyfill_code = v8::String::new(try_catch, V8_POLYFILLS).ok_or("Failed to create polyfill code")?;
    let polyfill_script = v8::Script::compile(try_catch, polyfill_code, None).ok_or("Failed to compile polyfills")?;
    if polyfill_script.run(try_catch).is_none() {
        if let Some(exception) = try_catch.exception() {
            let msg = exception.to_rust_string_lossy(try_catch);
            return Err(format!("Polyfill error: {}", msg));
        }
        return Err("Failed to run polyfills".to_string());
    }

    // Compile and run the bundle
    let code = v8::String::new(try_catch, js_code).ok_or("Failed to create JS code string")?;
    let script = match v8::Script::compile(try_catch, code, None) {
        Some(s) => s,
        None => {
            if let Some(exception) = try_catch.exception() {
                let msg = exception.to_rust_string_lossy(try_catch);
                return Err(format!("Compile error: {}", msg));
            }
            return Err("Failed to compile script".to_string());
        }
    };

    if script.run(try_catch).is_none() {
        if let Some(exception) = try_catch.exception() {
            let msg = exception.to_rust_string_lossy(try_catch);
            return Err(format!("Runtime error: {}", msg));
        }
        return Err("Failed to run script".to_string());
    }

    // Now call the render function
    let render_call = v8::String::new(try_catch, "render()").ok_or("Failed to create render call")?;
    let render_script = match v8::Script::compile(try_catch, render_call, None) {
        Some(s) => s,
        None => {
            if let Some(exception) = try_catch.exception() {
                let msg = exception.to_rust_string_lossy(try_catch);
                return Err(format!("Render compile error: {}", msg));
            }
            return Err("Failed to compile render call".to_string());
        }
    };

    let result = match render_script.run(try_catch) {
        Some(r) => r,
        None => {
            if let Some(exception) = try_catch.exception() {
                let msg = exception.to_rust_string_lossy(try_catch);
                return Err(format!("Render error: {}", msg));
            }
            return Err("Failed to execute render()".to_string());
        }
    };

    // Convert result to string
    let result_str = result.to_string(try_catch).ok_or("Failed to convert result to string")?;
    Ok(result_str.to_rust_string_lossy(try_catch))
}

// SSR Handler
async fn ssr_handler() -> impl IntoResponse {
    // Load the SSR bundle
    let js_code = match std::fs::read_to_string("dist/ssr/server.js") {
        Ok(code) => code,
        Err(e) => {
            eprintln!("Failed to read SSR bundle: {}", e);
            return Html(format!(
                r#"<!DOCTYPE html>
<html>
<head><title>Error</title></head>
<body><h1>SSR Error</h1><p>Failed to load SSR bundle. Make sure to run: cd frontend && bun run build</p><p>{}</p></body>
</html>"#,
                e
            ));
        }
    };

    // Execute the JavaScript and get rendered HTML
    let html = match execute_js(&js_code) {
        Ok(h) => h,
        Err(e) => {
            eprintln!("Failed to render: {}", e);
            return Html(format!(
                r#"<!DOCTYPE html>
<html>
<head><title>Error</title></head>
<body><h1>SSR Error</h1><p>Failed to render: {}</p></body>
</html>"#,
                e
            ));
        }
    };

    // Load CSS - try finding the actual CSS file
    let css = find_css_file().unwrap_or_default();

    let full_html = format!(
        r#"<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" type="image/svg+xml" href="/logo.svg" />
    <style>{}</style>
    <title>Vite + React + Rust (SSR)</title>
  </head>
  <body>
    <div id="root">{}</div>
    <script type="module" src="/assets/client.js"></script>
  </body>
</html>"#,
        css, html
    );

    Html(full_html)
}

fn find_css_file() -> Option<String> {
    // Try to find CSS file in dist/client/assets
    let assets_dir = std::path::Path::new("dist/client/assets");
    if assets_dir.exists() {
        if let Ok(entries) = std::fs::read_dir(assets_dir) {
            for entry in entries.flatten() {
                let path = entry.path();
                if path.extension().map_or(false, |ext| ext == "css") {
                    if let Ok(content) = std::fs::read_to_string(&path) {
                        return Some(content);
                    }
                }
            }
        }
    }
    // Fallback to direct path
    std::fs::read_to_string("dist/client/assets/index.css").ok()
}

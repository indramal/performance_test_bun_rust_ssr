use axum::{
    extract::Path,
    http::StatusCode,
    response::{Html, IntoResponse},
    routing::get,
    Router,
};
use askama::Template;
use serde::Serialize;
use std::{collections::HashMap, fs, sync::Arc};

#[derive(Template)]
#[template(path = "layout.html")]
struct LayoutTemplate<'a> {
    title: &'a str,
    meta_description: Option<&'a str>,
    js: &'a str,
    css: Option<&'a str>,
    initial_data: Option<String>, // JSON serialized
}

// Load manifest.json -> map logical entry to asset filenames
fn load_manifest() -> HashMap<String, serde_json::Value> {
    let manifest_str = fs::read_to_string("dist/.vite/manifest.json")
        .expect("manifest.json not found - did you run 'cd client && npm run build'?");
    serde_json::from_str(&manifest_str).expect("invalid manifest.json")
}

// Load route_titles.json -> map path to title
fn load_titles() -> HashMap<String, String> {
    let titles_str = fs::read_to_string("client/src/route_titles.json")
        .expect("route_titles.json not found");
    serde_json::from_str(&titles_str).expect("invalid route_titles.json")
}

#[tokio::main]
async fn main() {
    let manifest = Arc::new(load_manifest());
    let titles = Arc::new(load_titles());

    let app = Router::new()
        // Static assets
        .nest_service(
            "/assets",
            tower_http::services::ServeDir::new("dist/assets"),
        )
        // Catch-all for HTML pages
        .route(
            "/*path",
            get({
                let manifest = manifest.clone();
                let titles = titles.clone();
                move |path: Path<String>| {
                    let manifest = manifest.clone();
                    let titles = titles.clone();
                    async move { handle_page(path, manifest, titles).await }
                }
            }),
        )
        .route(
            "/",
            get({
                let manifest = manifest.clone();
                let titles = titles.clone();
                move || {
                    let manifest = manifest.clone();
                    let titles = titles.clone();
                    async move { handle_page(Path("".to_string()), manifest, titles).await }
                }
            }),
        );

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3003")
        .await
        .unwrap();
    
    println!("🚀 Server running at http://localhost:3003/");
    println!("📁 Serving assets from dist/assets/");
    
    axum::serve(listener, app).await.unwrap();
}

async fn handle_page(
    path: Path<String>,
    manifest: Arc<HashMap<String, serde_json::Value>>,
    titles: Arc<HashMap<String, String>>,
) -> impl IntoResponse {
    // Decide title based on path
    let route = path.0;
    let lookup_path = if route.is_empty() { "/".to_string() } else { format!("/{}", route) };
    
    let title = titles.get(&lookup_path).map(|s| s.as_str()).unwrap_or("React Manifest Askama");
    
    let meta_desc = match lookup_path.as_str() {
        "/" => "Welcome to the home page",
        "/about" => "Learn more about this project",
        _ => "A Vite + React + Axum + Askama app",
    };

    // Get assets for our entry (src/main.jsx)
    let entry = manifest.get("src/main.jsx");
    if entry.is_none() {
        return (
            StatusCode::INTERNAL_SERVER_ERROR,
            "Manifest missing 'src/main.jsx' entry. Check vite.config.js input path.",
        )
            .into_response();
    }
    let entry = entry.unwrap();

    // Derive js and css strings
    let js = entry
        .get("file")
        .and_then(|v| v.as_str())
        .map(|s| format!("/{}", s))
        .unwrap_or_else(|| "/assets/main.js".to_string());
    
    let css = entry
        .get("css")
        .and_then(|v| v.as_array())
        .and_then(|arr| arr.first())
        .and_then(|v| v.as_str())
        .map(|s| format!("/{}", s));

    // Optional initial data injection (example)
    #[derive(Serialize)]
    struct InitData {
        msg: &'static str,
        timestamp: u64,
    }
    let init = InitData {
        msg: "Hello from Axum server!",
        timestamp: std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs(),
    };
    let initial_data_json = serde_json::to_string(&init).ok();

    let tpl = LayoutTemplate {
        title,
        meta_description: Some(meta_desc),
        js: &js,
        css: css.as_deref(),
        initial_data: initial_data_json,
    };

    match tpl.render() {
        Ok(html) => Html(html).into_response(),
        Err(e) => (
            StatusCode::INTERNAL_SERVER_ERROR,
            format!("Template error: {}", e),
        )
            .into_response(),
    }
}

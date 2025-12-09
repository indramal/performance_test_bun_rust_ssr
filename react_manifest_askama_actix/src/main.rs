use actix_files::Files;
use actix_web::{web, App, HttpRequest, HttpResponse, HttpServer, Responder};
use askama::Template;
use serde::Serialize;
use std::{collections::HashMap, fs};

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

struct AppState {
    manifest: HashMap<String, serde_json::Value>,
    titles: HashMap<String, String>,
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let manifest = load_manifest();
    let titles = load_titles();
    
    let state = web::Data::new(AppState {
        manifest,
        titles,
    });

    println!("🚀 Server running at http://localhost:3004/");
    println!("📁 Serving assets from dist/assets/");

    HttpServer::new(move || {
        App::new()
            .app_data(state.clone())
            // Static assets
            .service(Files::new("/assets", "dist/assets"))
            // Catch-all for HTML pages
            .default_service(web::get().to(handle_page))
    })
    .bind(("0.0.0.0", 3004))?
    .run()
    .await
}

async fn handle_page(req: HttpRequest, state: web::Data<AppState>) -> impl Responder {
    let path = req.path();
    let lookup_path = if path == "/" || path.is_empty() { 
        "/".to_string() 
    } else { 
        path.to_string() 
    };
    
    let title = state.titles.get(&lookup_path).map(|s| s.as_str()).unwrap_or("React Manifest Askama");
    
    let meta_desc = match lookup_path.as_str() {
        "/" => "Welcome to the home page",
        "/about" => "Learn more about this project",
        _ => "A Vite + React + Axum + Askama app", // Keeping the text similar, maybe should update "Axum" to "Actix"
    };

    // Get assets for our entry (src/main.jsx)
    let entry = state.manifest.get("src/main.jsx");
    if entry.is_none() {
        return HttpResponse::InternalServerError().body("Manifest missing 'src/main.jsx' entry. Check vite.config.js input path.");
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
        msg: "Hello from Actix server!",
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
        Ok(html) => HttpResponse::Ok().content_type("text/html").body(html),
        Err(e) => HttpResponse::InternalServerError().body(format!("Template error: {}", e)),
    }
}

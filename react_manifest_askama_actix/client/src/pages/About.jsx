import { useEffect } from "react";
import titles from "../route_titles.json";

export default function About() {
  // Update title for client-side navigation
  useEffect(() => {
    document.title = titles["/about"];
  }, []);

  return (
    <div style={{ maxWidth: "800px", margin: "0 auto" }}>
      <h1
        style={{ color: "#7c3aed", fontSize: "2.5rem", marginBottom: "1rem" }}
      >
        ℹ️ About This Project
      </h1>

      <div
        style={{
          background: "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)",
          color: "white",
          padding: "2rem",
          borderRadius: "12px",
          marginBottom: "2rem",
          boxShadow: "0 4px 6px rgba(0,0,0,0.1)",
        }}
      >
        <h2 style={{ marginTop: 0 }}>React Manifest Askama</h2>
        <p style={{ fontSize: "1.1rem", lineHeight: "1.6", marginBottom: 0 }}>
          A modern web architecture combining the best of Rust and React
          ecosystems.
        </p>
      </div>

      <div style={{ marginBottom: "2rem" }}>
        <h3 style={{ color: "#1f2937", marginBottom: "1rem" }}>
          🎯 How It Works
        </h3>

        <div style={{ marginLeft: "1rem" }}>
          <div style={{ marginBottom: "1.5rem" }}>
            <h4 style={{ color: "#4b5563", marginBottom: "0.5rem" }}>
              1. Build Process
            </h4>
            <p
              style={{
                color: "#6b7280",
                lineHeight: "1.6",
                marginLeft: "1rem",
              }}
            >
              Vite builds the React application and generates a{" "}
              <code>manifest.json</code>
              file that maps logical entry points to hashed asset filenames.
            </p>
          </div>

          <div style={{ marginBottom: "1.5rem" }}>
            <h4 style={{ color: "#4b5563", marginBottom: "0.5rem" }}>
              2. Server Rendering
            </h4>
            <p
              style={{
                color: "#6b7280",
                lineHeight: "1.6",
                marginLeft: "1rem",
              }}
            >
              Axum loads the manifest at startup and uses Askama templates to
              render HTML shells for each route, injecting the correct asset
              URLs and metadata.
            </p>
          </div>

          <div style={{ marginBottom: "1.5rem" }}>
            <h4 style={{ color: "#4b5563", marginBottom: "0.5rem" }}>
              3. Client Hydration
            </h4>
            <p
              style={{
                color: "#6b7280",
                lineHeight: "1.6",
                marginLeft: "1rem",
              }}
            >
              The browser loads the JavaScript bundle, React mounts to the DOM,
              and TanStack Router takes over client-side navigation.
            </p>
          </div>

          <div style={{ marginBottom: "1.5rem" }}>
            <h4 style={{ color: "#4b5563", marginBottom: "0.5rem" }}>
              4. Data Fetching
            </h4>
            <p
              style={{
                color: "#6b7280",
                lineHeight: "1.6",
                marginLeft: "1rem",
              }}
            >
              TanStack Query handles data fetching with support for
              server-injected initial data via{" "}
              <code>window.__INITIAL_DATA__</code>.
            </p>
          </div>
        </div>
      </div>

      <div
        style={{
          background: "#e0e7ff",
          border: "1px solid #818cf8",
          padding: "1.5rem",
          borderRadius: "8px",
        }}
      >
        <h3 style={{ marginTop: 0, color: "#4338ca" }}>✨ Key Features</h3>
        <ul style={{ color: "#4338ca", lineHeight: "1.8" }}>
          <li>🚀 Fast builds with Vite</li>
          <li>⚡ Client-side rendering (no SSR complexity)</li>
          <li>🦀 Blazing fast Rust server</li>
          <li>📄 Clean template separation with Askama</li>
          <li>🎯 SEO-friendly with per-route meta tags</li>
          <li>🔄 TanStack Router for client routing</li>
          <li>💾 TanStack Query for data management</li>
          <li>🎨 Automatic asset hash busting</li>
        </ul>
      </div>

      <div
        style={{
          marginTop: "2rem",
          padding: "1rem",
          background: "#f9fafb",
          borderRadius: "8px",
        }}
      >
        <p style={{ margin: 0, color: "#6b7280", fontSize: "0.875rem" }}>
          <strong>Note:</strong> This page demonstrates client-side routing.
          Notice how the page title in the browser tab changes between routes,
          even though React handles navigation client-side.
        </p>
      </div>
    </div>
  );
}

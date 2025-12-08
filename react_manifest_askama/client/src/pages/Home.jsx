import { useQuery } from "@tanstack/react-query";
import { useEffect } from "react";
import titles from "../route_titles.json";

export default function Home() {
  // Update title for client-side navigation
  useEffect(() => {
    document.title = titles["/"];
  }, []);

  // Example TanStack Query usage
  // This will use hydrated data from window.__INITIAL_DATA__ if available
  const { data, isLoading, error } = useQuery({
    queryKey: ["homeData"],
    queryFn: async () => {
      // This is a fallback fetch if no initial data is provided
      // In production, you'd fetch from a real API
      const response = await fetch("/api/home-data");
      if (!response.ok) {
        // For demo purposes, return mock data
        return {
          title: "Welcome to React Manifest Askama",
          description:
            "This is a Vite + React CSR app with Axum + Askama integration",
        };
      }
      return response.json();
    },
    // Use initial data from server if available
    initialData: window.__INITIAL_DATA__,
  });

  if (isLoading) return <div>Loading...</div>;
  if (error) return <div>Error: {error.message}</div>;

  return (
    <div style={{ maxWidth: "800px", margin: "0 auto" }}>
      <h1
        style={{ color: "#2563eb", fontSize: "2.5rem", marginBottom: "1rem" }}
      >
        🏠 Home Page
      </h1>

      <div
        style={{
          background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
          color: "white",
          padding: "2rem",
          borderRadius: "12px",
          marginBottom: "2rem",
          boxShadow: "0 4px 6px rgba(0,0,0,0.1)",
        }}
      >
        <h2 style={{ marginTop: 0 }}>Welcome! 👋</h2>
        <p style={{ fontSize: "1.1rem", marginBottom: 0 }}>
          This is a client-side rendered React application powered by:
        </p>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "repeat(auto-fit, minmax(200px, 1fr))",
          gap: "1rem",
          marginBottom: "2rem",
        }}
      >
        <div
          style={{
            background: "#f3f4f6",
            padding: "1.5rem",
            borderRadius: "8px",
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: "2rem", marginBottom: "0.5rem" }}>⚡</div>
          <strong>Vite</strong>
          <div
            style={{
              fontSize: "0.875rem",
              color: "#6b7280",
              marginTop: "0.5rem",
            }}
          >
            Fast build tool
          </div>
        </div>

        <div
          style={{
            background: "#f3f4f6",
            padding: "1.5rem",
            borderRadius: "8px",
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: "2rem", marginBottom: "0.5rem" }}>⚛️</div>
          <strong>React 19</strong>
          <div
            style={{
              fontSize: "0.875rem",
              color: "#6b7280",
              marginTop: "0.5rem",
            }}
          >
            UI library
          </div>
        </div>

        <div
          style={{
            background: "#f3f4f6",
            padding: "1.5rem",
            borderRadius: "8px",
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: "2rem", marginBottom: "0.5rem" }}>🦀</div>
          <strong>Axum</strong>
          <div
            style={{
              fontSize: "0.875rem",
              color: "#6b7280",
              marginTop: "0.5rem",
            }}
          >
            Rust server
          </div>
        </div>

        <div
          style={{
            background: "#f3f4f6",
            padding: "1.5rem",
            borderRadius: "8px",
            textAlign: "center",
          }}
        >
          <div style={{ fontSize: "2rem", marginBottom: "0.5rem" }}>📄</div>
          <strong>Askama</strong>
          <div
            style={{
              fontSize: "0.875rem",
              color: "#6b7280",
              marginTop: "0.5rem",
            }}
          >
            Templates
          </div>
        </div>
      </div>

      <div
        style={{
          background: "#fef3c7",
          border: "1px solid #fbbf24",
          padding: "1rem",
          borderRadius: "8px",
          marginBottom: "1rem",
        }}
      >
        <strong>💡 Server Data:</strong>
        <pre
          style={{
            background: "white",
            padding: "1rem",
            borderRadius: "4px",
            marginTop: "0.5rem",
            overflow: "auto",
          }}
        >
          {JSON.stringify(data, null, 2)}
        </pre>
      </div>

      <p style={{ color: "#6b7280" }}>
        The content above was hydrated from <code>window.__INITIAL_DATA__</code>
        injected by the Axum server through the Askama template.
      </p>
    </div>
  );
}

import { serve } from "bun";
import { renderToString } from "react-dom/server";
import App from "./App";

// Build client bundle on server start if it doesn't exist
const buildClient = async () => {
  try {
    await Bun.build({
      entrypoints: ["./src/frontend.tsx"],
      outdir: "./dist",
      naming: "[dir]/client.[ext]",
      target: "browser",
      minify: process.env.NODE_ENV === "production",
      sourcemap: process.env.NODE_ENV !== "production" ? "external" : "none",
    });
    console.log("✅ Client bundle built successfully");
  } catch (error) {
    console.error("❌ Failed to build client bundle:", error);
  }
};

// Build client bundle on startup
await buildClient();

// SSR Cache - 2-day TTL
interface CacheEntry {
  html: string;
  timestamp: number;
}

const ssrCache = new Map<string, CacheEntry>();
const CACHE_TTL = 2 * 24 * 60 * 60 * 1000; // 2 days in milliseconds

// Periodic cache cleanup (every hour)
setInterval(() => {
  const now = Date.now();
  let cleaned = 0;
  for (const [key, entry] of ssrCache.entries()) {
    if (now - entry.timestamp > CACHE_TTL) {
      ssrCache.delete(key);
      cleaned++;
    }
  }
  if (cleaned > 0) {
    console.log(`🧹 Cleaned ${cleaned} expired cache entries`);
  }
}, 60 * 60 * 1000); // Run every hour

const server = serve({
  routes: {
    // Serve client bundle
    "/client.js": async () => {
      const file = Bun.file("./dist/client.js");
      return new Response(file, {
        headers: { "Content-Type": "application/javascript" },
      });
    },

    // Serve CSS
    "/index.css": async () => {
      const file = Bun.file("./src/index.css");
      return new Response(file, {
        headers: { "Content-Type": "text/css" },
      });
    },

    // Serve SVG assets
    "/logo.svg": async () => {
      const file = Bun.file("./src/logo.svg");
      return new Response(file, {
        headers: { "Content-Type": "image/svg+xml" },
      });
    },

    "/react.svg": async () => {
      const file = Bun.file("./src/react.svg");
      return new Response(file, {
        headers: { "Content-Type": "image/svg+xml" },
      });
    },

    // API routes
    "/api/hello": {
      async GET(req) {
        return Response.json({
          message: "Hello, world!",
          method: "GET",
        });
      },
      async PUT(req) {
        return Response.json({
          message: "Hello, world!",
          method: "PUT",
        });
      },
    },

    "/api/hello/:name": async (req) => {
      const name = req.params.name;
      return Response.json({
        message: `Hello, ${name}!`,
      });
    },

    // SSR route with caching - serve for all other routes
    "/*": async (req) => {
      try {
        const url = new URL(req.url).pathname;
        const now = Date.now();

        // Check cache
        const cached = ssrCache.get(url);
        if (cached && now - cached.timestamp < CACHE_TTL) {
          const age = Math.floor((now - cached.timestamp) / 1000);
          console.log(`✓ Cache HIT for ${url} (age: ${age}s)`);

          return new Response(cached.html, {
            headers: {
              "Content-Type": "text/html",
              "X-Cache": "HIT",
              "X-Cache-Age": age.toString(),
              "Cache-Control": "public, max-age=172800", // 2 days
            },
          });
        }

        console.log(`✗ Cache MISS for ${url} - rendering...`);

        // Render the React app to string
        const appHtml = renderToString(<App />);

        // Create complete HTML document with SSR content
        const html = `<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <link rel="icon" type="image/svg+xml" href="/logo.svg" />
    <link rel="stylesheet" href="/index.css" />
    <title>Bun + React (SSR + Cache)</title>
  </head>
  <body>
    <div id="root">${appHtml}</div>
    <script type="module" src="/client.js"></script>
  </body>
</html>`;

        // Store in cache
        ssrCache.set(url, { html, timestamp: now });
        console.log(`💾 Cached ${url} (total entries: ${ssrCache.size})`);

        return new Response(html, {
          headers: {
            "Content-Type": "text/html",
            "X-Cache": "MISS",
            "Cache-Control": "public, max-age=172800", // 2 days
          },
        });
      } catch (error) {
        console.error("SSR Error:", error);
        return new Response("Internal Server Error", { status: 500 });
      }
    },
  },

  development: process.env.NODE_ENV !== "production" && {
    // Enable browser hot reloading in development
    hmr: true,

    // Echo console logs from the browser to the server
    console: true,
  },
});

console.log(`🚀 Server running at ${server.url}`);

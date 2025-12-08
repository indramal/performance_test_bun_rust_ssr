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

    // SSR route - serve for all other routes
    "/*": async () => {
      try {
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
    <title>Bun + React (SSR)</title>
  </head>
  <body>
    <div id="root">${appHtml}</div>
    <script type="module" src="/client.js"></script>
  </body>
</html>`;

        return new Response(html, {
          headers: { "Content-Type": "text/html" },
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

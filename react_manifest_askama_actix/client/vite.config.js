import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: "../dist", // Build into server/dist
    manifest: true, // Generate manifest.json
    emptyOutDir: true, // Force empty outDir even if outside root
    rollupOptions: {
      input: "/src/main.jsx", // Single entry point
    },
  },
  base: "/", // Adjust if deploying under a subpath
});

import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// SSR build configuration - use browser target to bundle everything
export default defineConfig({
  plugins: [react()],
  build: {
    outDir: "../dist/ssr",
    emptyOutDir: true,
    target: "es2020",
    lib: {
      entry: "./src/server.tsx",
      name: "SSR",
      formats: ["iife"],
      fileName: () => "server.js",
    },
    rollupOptions: {
      output: {
        extend: true,
      },
    },
  },
});

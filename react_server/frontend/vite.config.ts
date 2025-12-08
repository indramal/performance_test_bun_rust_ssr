import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// Client build configuration
export default defineConfig({
  plugins: [react()],
  build: {
    outDir: "../dist/client",
    emptyOutDir: true,
    rollupOptions: {
      input: "./src/client.tsx",
      output: {
        entryFileNames: "assets/client.js",
        assetFileNames: "assets/[name][extname]",
      },
    },
  },
});

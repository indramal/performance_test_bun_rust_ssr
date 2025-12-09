import React from "react";
import { createRoot } from "react-dom/client";
import {
  QueryClient,
  QueryClientProvider,
  HydrationBoundary,
} from "@tanstack/react-query";
import { RouterProvider } from "@tanstack/react-router";
import router from "./router";

// Create a client
const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      staleTime: 1000 * 60 * 5, // 5 minutes
    },
  },
});

// Get initial data from server if available
const initialData = window.__INITIAL_DATA__ ?? null;

const rootElement = document.getElementById("root");
if (!rootElement) {
  throw new Error("Root element not found");
}

createRoot(rootElement).render(
  <React.StrictMode>
    <QueryClientProvider client={queryClient}>
      <HydrationBoundary state={initialData}>
        <RouterProvider router={router} />
      </HydrationBoundary>
    </QueryClientProvider>
  </React.StrictMode>
);

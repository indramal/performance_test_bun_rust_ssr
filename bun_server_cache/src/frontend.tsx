/**
 * This file is the entry point for the React app on the client side.
 * It hydrates the server-rendered HTML instead of replacing it.
 *
 * This is loaded by the server-rendered HTML via <script> tag.
 */

import { StrictMode } from "react";
import { hydrateRoot } from "react-dom/client";
import { App } from "./App";

const elem = document.getElementById("root")!;
const app = (
  <StrictMode>
    <App />
  </StrictMode>
);

// Hydrate the server-rendered content
// This attaches event listeners and makes the app interactive
// without re-rendering the entire content
hydrateRoot(elem, app);

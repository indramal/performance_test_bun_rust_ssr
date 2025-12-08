// Import polyfills FIRST
import "cross-fetch/polyfill";
import "urlpattern-polyfill";

import { renderToString } from "react-dom/server";
import { App } from "./components/App";

// Export render function for ssr_rs to call
export function render() {
  return renderToString(<App />);
}

// Make it available globally for ssr_rs
(globalThis as unknown as { render: () => string }).render = render;

import { StrictMode } from "react";
import { hydrateRoot } from "react-dom/client";
import { App } from "./components/App";

const elem = document.getElementById("root")!;
hydrateRoot(
  elem,
  <StrictMode>
    <App />
  </StrictMode>
);

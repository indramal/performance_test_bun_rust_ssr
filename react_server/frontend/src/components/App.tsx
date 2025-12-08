import { APITester } from "./APITester";
import "../index.css";

export function App() {
  return (
    <div className="app">
      <div className="logo-container">
        <img src="/logo.svg" alt="Vite Logo" className="logo bun-logo" />
        <img src="/react.svg" alt="React Logo" className="logo react-logo" />
      </div>

      <h1>Vite + React + Rust (SSR)</h1>
      <p>
        Edit <code>src/components/App.tsx</code> and save to test HMR
      </p>
      <APITester />
    </div>
  );
}

export default App;

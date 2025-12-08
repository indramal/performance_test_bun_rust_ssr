import React, { Suspense } from "react";
import {
  createRouter,
  createRoute,
  createRootRoute,
  Outlet,
  Link,
} from "@tanstack/react-router";

// Lazy load route components
const Home = React.lazy(() => import("./pages/Home"));
const About = React.lazy(() => import("./pages/About"));

// Loading fallback
const Loading = () => (
  <div style={{ padding: "2rem", textAlign: "center", color: "#6b7280" }}>
    Loading...
  </div>
);

// Create root route
const rootRoute = createRootRoute({
  component: () => (
    <div>
      <nav style={{ padding: "1rem", borderBottom: "1px solid #ccc" }}>
        <Link to="/" style={{ marginRight: "1rem" }}>
          Home
        </Link>
        <Link to="/about">About</Link>
      </nav>
      <div style={{ padding: "1rem" }}>
        <Suspense fallback={<Loading />}>
          <Outlet />
        </Suspense>
      </div>
    </div>
  ),
});

// Create routes
const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/",
  component: Home,
});

const aboutRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: "/about",
  component: About,
});

// Create route tree
const routeTree = rootRoute.addChildren([indexRoute, aboutRoute]);

// Create router
const router = createRouter({ routeTree });

export default router;

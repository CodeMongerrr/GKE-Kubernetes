const express = require("express");
const path = require("path");
const os = require("os");

const app = express();
const PORT = process.env.PORT || 3000;

// Inside the cluster, the frontend reaches the backend by its Service name.
// "backend-service" resolves via Kubernetes DNS to the backend pods.
const BACKEND_URL = process.env.BACKEND_URL || "http://backend-service:8080";

// Serve the static HTML page.
app.use(express.static(path.join(__dirname, "..", "public")));

// Health check — used by Kubernetes liveness/readiness probes.
app.get("/healthz", (req, res) => {
  res.status(200).send("ok");
});

// Proxy endpoint: the browser calls /api, and the frontend server (server-side)
// calls the internal backend Service. This is how an external page talks to an
// internal-only (ClusterIP) backend.
app.get("/api", async (req, res) => {
  try {
    const r = await fetch(BACKEND_URL + "/");
    const data = await r.json();
    res.json({ frontendPod: os.hostname(), backend: data });
  } catch (err) {
    res.status(502).json({ frontendPod: os.hostname(), error: String(err) });
  }
});

// Only start the server when run directly (`node src/server.js`).
// When imported by tests, we export the app instead so Supertest can drive it.
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Frontend listening on port ${PORT}`);
  });
}

module.exports = app;

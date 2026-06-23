const express = require("express");
const os = require("os");

const app = express();
const PORT = process.env.PORT || 8080;

// The git commit this image was built from. Baked in at `docker build` time
// (see Dockerfile ARG/ENV GIT_SHA) and injected by CI as ${{ github.sha }}.
// This is the value you watch change to PROVE a new image actually rolled out.
const COMMIT = process.env.GIT_SHA || "dev";

// Main endpoint — returns the pod's hostname so you can SEE load balancing
// spread requests across multiple backend pods.
app.get("/", (req, res) => {
  res.json({
    message: "Hello from the backend!",
    pod: os.hostname(),
    commit: COMMIT,
    time: new Date().toISOString(),
  });
});

// Version endpoint — returns the build's git commit. Curl this after a deploy
// to confirm the running image changed (the commit should match the SHA you
// just pushed to main).
app.get("/version", (req, res) => {
  res.json({ commit: COMMIT, pod: os.hostname() });
});

// Health check — used by Kubernetes liveness/readiness probes.
app.get("/health", (req, res) => {
  res.status(200).send("ok");
});

// CPU-burn endpoint — hit this in a loop to trigger the HorizontalPodAutoscaler.
// Burn duration is configurable so tests can run it instantly.
const LOAD_BURN_MS = Number(process.env.LOAD_BURN_MS) || 2000;
app.get("/load", (req, res) => {
  const end = Date.now() + LOAD_BURN_MS;
  while (Date.now() < end) {
    Math.sqrt(Math.random());
  }
  res.json({ message: `burned CPU for ${LOAD_BURN_MS}ms`, pod: os.hostname() });
});

// Only start the server when run directly (`node src/index.js`).
// When imported by tests, we export the app instead so Supertest can drive it.
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`Backend listening on port ${PORT}`);
  });
}

module.exports = app;

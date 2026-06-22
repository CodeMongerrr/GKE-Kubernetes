const request = require("supertest");

// Keep the CPU-burn endpoint fast during tests.
process.env.LOAD_BURN_MS = "10";

const app = require("../src/index");

describe("backend API", () => {
  test("GET / returns a greeting with the pod hostname", async () => {
    const res = await request(app).get("/");
    expect(res.status).toBe(200);
    expect(res.body.message).toBe("Hello from the backend!");
    expect(typeof res.body.pod).toBe("string");
    expect(res.body.pod.length).toBeGreaterThan(0);
    expect(typeof res.body.time).toBe("string");
  });

  test("GET /health returns 200 ok (probe target)", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.text).toBe("ok");
  });

  test("GET /load burns CPU and reports back", async () => {
    const res = await request(app).get("/load");
    expect(res.status).toBe(200);
    expect(res.body.message).toContain("burned CPU");
    expect(typeof res.body.pod).toBe("string");
  });

  test("unknown route returns 404", async () => {
    const res = await request(app).get("/does-not-exist");
    expect(res.status).toBe(404);
  });
});

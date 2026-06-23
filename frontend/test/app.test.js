const request = require("supertest");
const app = require("../src/server");

describe("frontend server", () => {
  afterEach(() => {
    delete global.fetch;
  });

  test("GET /healthz returns 200 ok (probe target)", async () => {
    const res = await request(app).get("/healthz");
    expect(res.status).toBe(200);
    expect(res.text).toBe("ok");
  });

  test("GET / serves the static index page", async () => {
    const res = await request(app).get("/");
    expect(res.status).toBe(200);
    expect(res.headers["content-type"]).toMatch(/html/);
  });

  test("GET /api proxies the backend and wraps the response", async () => {
    // Pretend the backend service answered successfully.
    global.fetch = jest.fn().mockResolvedValue({
      json: async () => ({ message: "Hello from the backend!", pod: "backend-xyz" }),
    });

    const res = await request(app).get("/api");
    expect(res.status).toBe(200);
    expect(global.fetch).toHaveBeenCalledTimes(1);
    expect(typeof res.body.frontendPod).toBe("string");
    expect(res.body.backend.pod).toBe("backend-xyz");
  });

  test("GET /api returns 502 when the backend is unreachable", async () => {
    global.fetch = jest.fn().mockRejectedValue(new Error("connection refused"));

    const res = await request(app).get("/api");
    expect(res.status).toBe(502);
    expect(res.body.error).toContain("connection refused");
  });
});

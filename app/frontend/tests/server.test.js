// Node 20+
import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import http from "node:http";
import { spawn } from "node:child_process";
import { fileURLToPath } from "node:url";
import path from "node:path";

let backend;
let frontend;
let frontendExited = false;
let frontendExitCode = null;

const BACKEND_PORT = 5055;
const FRONTEND_PORT = 3001;

const hereFile = fileURLToPath(import.meta.url);
const hereDir = path.dirname(hereFile);
const frontendDir = path.resolve(hereDir, ".."); // app/frontend/

async function waitForHealth(url, timeoutMs = 8000) {
  const t0 = Date.now();
  while (Date.now() - t0 < timeoutMs) {
    if (frontendExited) return false;
    try {
      const r = await fetch(url);
      if (r.ok) return true;
    } catch {}
    await new Promise(r => setTimeout(r, 150));
  }
  return false;
}

before(async () => {
  // Mock backend
  backend = http.createServer((req, res) => {
    if (req.url.startsWith("/generate")) {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ url: req.url, password: "X".repeat(12) }));
    } else if (req.url.startsWith("/passwords")) {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify([]));
    } else if (req.url.startsWith("/health")) {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ status: "ok" }));
    } else {
      res.writeHead(404); res.end();
    }
  }).listen(BACKEND_PORT, "127.0.0.1");

  // Start frontend
  frontend = spawn(
    process.execPath,
    ["server.js"],
    {
      cwd: frontendDir,
      env: {
        ...process.env,
        PORT: String(FRONTEND_PORT),
        BACKEND_URL: `http://127.0.0.1:${BACKEND_PORT}`
      },
      stdio: "inherit",
      windowsHide: true,
    }
  );
  frontend.on("exit", code => { frontendExited = true; frontendExitCode = code; });

  const ok = await waitForHealth(`http://127.0.0.1:${FRONTEND_PORT}/health`, 10000);
  assert.ok(ok, `frontend /health did not become ready${frontendExited ? ` (frontend exited with code ${frontendExitCode})` : ""}`);
});

after(async () => {
  try { frontend && frontend.kill(); } catch {}
  await new Promise(r => backend.close(r));
});

test("frontend health endpoint responds", async () => {
  const r = await fetch(`http://127.0.0.1:${FRONTEND_PORT}/health`);
  assert.equal(r.status, 200);
  const data = await r.json();
  assert.equal(data.status, "ok");
});

test("frontend preserves query string to backend", async () => {
  const qs = "length=22&digits=false&symbols=false&uppercase=true";
  const r = await fetch(`http://127.0.0.1:${FRONTEND_PORT}/api/generate?${qs}`);
  assert.equal(r.status, 200);
  const data = await r.json();
  assert.ok(data.url.includes(qs), `expected backend to receive query: ${qs}, got: ${data.url}`);
});

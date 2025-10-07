import express from "express";
import path from "path";
import morgan from "morgan";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;
const BACKEND_URL = process.env.BACKEND_URL || "http://localhost:5000";

app.use(morgan("tiny"));
app.use(express.static(path.join(__dirname, "public")));
app.use(express.json());

app.get("/health", (req, res) => res.json({ status: "ok" }));

// Generic proxy for /api/*
app.all("/api/*", async (req, res) => {
  // Preserve the path after /api and KEEP the query string
  const pathAfterApi = req.path.replace(/^\/api/, "");
  const qs = req.url.includes("?") ? req.url.slice(req.url.indexOf("?")) : "";
  const target = BACKEND_URL + pathAfterApi + qs;

  const opts = { method: req.method, headers: {} };

  // Forward JSON body for non-GET requests
  if (req.method !== "GET" && req.body && Object.keys(req.body).length > 0) {
    opts.headers["Content-Type"] = "application/json";
    opts.body = JSON.stringify(req.body);
  }

  try {
    const r = await fetch(target, opts);
    const ct = r.headers.get("content-type") || "";
    const data = ct.includes("application/json") ? await r.json() : await r.text();
    res.status(r.status).send(data);
  } catch (e) {
    res.status(502).json({ error: "backend unreachable" });
  }
});

app.listen(PORT, () => console.log(`Frontend running on port ${PORT}`));

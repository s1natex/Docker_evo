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

app.get("/health", (req, res) => res.json({ status: "ok" }));

app.get("/api/generate", async (req, res) => {
  const u = new URL("/generate", BACKEND_URL);
  ["length", "digits", "symbols", "uppercase"].forEach(k => {
    if (typeof req.query[k] !== "undefined") u.searchParams.set(k, req.query[k]);
  });
  try {
    const r = await fetch(u.toString(), { redirect: "follow" });
    const ct = r.headers.get("content-type") || "";
    const body = ct.includes("application/json") ? await r.json() : await r.text();
    res.status(r.status).send(body);
  } catch {
    res.status(502).json({ error: "backend unreachable" });
  }
});

app.listen(PORT);

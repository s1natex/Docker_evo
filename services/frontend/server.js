import express from "express";
const app = express();

const PORT = process.env.PORT || 3000;
const BACKEND_BASE = process.env.BACKEND_URL || "http://pass-gen:5000";

app.use(express.static("public"));

app.get("/api/generate", async (req, res) => {
  try {
    const qs = new URLSearchParams(req.query).toString();
    const url = `${BACKEND_BASE}/generate${qs ? "?" + qs : ""}`;
    const r = await fetch(url);
    const data = await r.json();
    res.status(r.status).json(data);
  } catch (e) {
    res.status(500).json({ error: "proxy_error", detail: String(e) });
  }
});

app.get("/health", (_, res) => res.json({ status: "ok" }));

app.listen(PORT, () => {
  console.log(`Frontend listening on http://0.0.0.0:${PORT}`);
});

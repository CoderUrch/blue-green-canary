const express = require("express");
const { Client } = require("pg");

const app = express();
const port = 3000;

// DB config (hardcoded FOR NOW)
const client = new Client({
  host: process.env.DB_HOST || "db",
  user: process.env.DB_USER || "appuser",
  password: process.env.DB_PASSWORD || "apppassword",
  database: process.env.DB_NAME || "appdb",
});

client.connect()
  .then(() => console.log("Connected to DB"))
  .catch(err => console.error("DB connection error", err));

app.get("/api", async (req, res) => {
  res.json({
    message: "Hello from backend",
    db: "connected"
  });
});

app.listen(port, () => {
  console.log(`Backend running on port ${port}`);
});

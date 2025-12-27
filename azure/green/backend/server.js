const express = require("express");
const { Client } = require("pg");
const { SecretsManagerClient, GetSecretValueCommand } = require("@aws-sdk/client-secrets-manager");

const app = express();
const port = 3000;

// AWS region and secret name from env
const region = process.env.AWS_REGION || "eu-north-1";
const secretName = process.env.SECRET_ID || "db-secret";

// Create Secrets Manager client
const smClient = new SecretsManagerClient({ region });

async function getDbConfig() {
  try {
    const command = new GetSecretValueCommand({ SecretId: secretName });
    const data = await smClient.send(command);
    const secret = JSON.parse(data.SecretString);

    return {
      host: secret.host,
      user: secret.username,
      password: secret.password,
      database: secret.database,
    };
  } catch (err) {
    console.error("Error fetching secret:", err);
    process.exit(1);
  }
}

async function startApp() {
  const dbConfig = await getDbConfig();

  const client = new Client(dbConfig);

  await client.connect();
  console.log("Connected to DB");

  app.get("/api", async (req, res) => {
    res.json({
      message: "Hello from backend",
      db: "connected"
    });
  });

  app.listen(port, () => {
    console.log(`Backend running on port ${port}`);
  });
}

startApp();

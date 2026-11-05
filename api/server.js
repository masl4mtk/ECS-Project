const express = require('express');
const { Pool } = require('pg');
const { SQSClient, SendMessageCommand } = require('@aws-sdk/client-sqs');

const PORT = process.env.PORT || 3000;
const QUEUE_URL = process.env.SQS_QUEUE_URL;

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || 'orders',
  user: process.env.DB_USER || 'orders',
  password: process.env.DB_PASSWORD || 'orders',
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

// SQS_ENDPOINT is only set locally (ElasticMQ). On AWS it is left empty.
const sqs = new SQSClient({
  region: process.env.AWS_REGION || 'us-east-1',
  ...(process.env.SQS_ENDPOINT ? { endpoint: process.env.SQS_ENDPOINT } : {}),
});

async function initDb(retries = 15) {
  for (let i = 0; i < retries; i++) {
    try {
      await pool.query(`
        CREATE TABLE IF NOT EXISTS orders (
          id SERIAL PRIMARY KEY,
          customer VARCHAR(100) NOT NULL,
          item VARCHAR(100) NOT NULL,
          quantity INT NOT NULL CHECK (quantity > 0),
          status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
          created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
          updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )`);
      console.log('Database ready');
      return;
    } catch (err) {
      console.log(`DB not ready (${err.message}), retrying...`);
      await new Promise((r) => setTimeout(r, 2000));
    }
  }
  throw new Error('Could not connect to database');
}

const app = express();
app.use(express.json());

// Liveness: process is up (use for ALB target group health check)
app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

// Readiness: DB reachable
app.get('/api/ready', async (_req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ready' });
  } catch {
    res.status(503).json({ status: 'db unavailable' });
  }
});

app.post('/api/orders', async (req, res) => {
  const { customer, item, quantity } = req.body || {};
  const qty = Number(quantity);
  if (!customer || !item || !Number.isInteger(qty) || qty < 1) {
    return res.status(400).json({ error: 'customer, item and a positive integer quantity are required' });
  }
  try {
    const { rows } = await pool.query(
      'INSERT INTO orders (customer, item, quantity) VALUES ($1, $2, $3) RETURNING *',
      [String(customer).slice(0, 100), String(item).slice(0, 100), qty]
    );
    const order = rows[0];
    await sqs.send(new SendMessageCommand({
      QueueUrl: QUEUE_URL,
      MessageBody: JSON.stringify({ orderId: order.id }),
    }));
    res.status(201).json(order);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

app.get('/api/orders', async (_req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM orders ORDER BY id DESC LIMIT 50');
    res.json(rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

app.get('/api/orders/:id', async (req, res) => {
  try {
    const { rows } = await pool.query('SELECT * FROM orders WHERE id = $1', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Not found' });
    res.json(rows[0]);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch order' });
  }
});

app.get('/api/stats', async (_req, res) => {
  try {
    const { rows } = await pool.query('SELECT status, COUNT(*)::int AS count FROM orders GROUP BY status');
    res.json(rows);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

initDb()
  .then(() => {
    const server = app.listen(PORT, () => console.log(`API listening on ${PORT}`));
    process.on('SIGTERM', () => {
      console.log('SIGTERM received, shutting down');
      server.close(() => pool.end().then(() => process.exit(0)));
    });
  })
  .catch((err) => {
    console.error(err);
    process.exit(1);
  });

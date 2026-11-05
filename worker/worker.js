const { Pool } = require('pg');
const { SQSClient, ReceiveMessageCommand, DeleteMessageCommand } = require('@aws-sdk/client-sqs');

const QUEUE_URL = process.env.SQS_QUEUE_URL;
const MAX_RECEIVES = Number(process.env.MAX_RECEIVES || 3); // keep in sync with the DLQ maxReceiveCount

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 5432),
  database: process.env.DB_NAME || 'orders',
  user: process.env.DB_USER || 'orders',
  password: process.env.DB_PASSWORD || 'orders',
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
});

const sqs = new SQSClient({
  region: process.env.AWS_REGION || 'us-east-1',
  ...(process.env.SQS_ENDPOINT ? { endpoint: process.env.SQS_ENDPOINT } : {}),
});

let running = true;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function processOrder(orderId, customer) {
  await pool.query("UPDATE orders SET status='PROCESSING', updated_at=NOW() WHERE id=$1", [orderId]);
  // Simulate work (payment, stock check, etc.) for 3-6 seconds
  await sleep(3000 + Math.random() * 3000);
  // Demo: use customer name "fail" to trigger retries and the dead-letter queue
  if (customer && customer.toLowerCase() === 'fail') throw new Error('Simulated failure');
  await pool.query("UPDATE orders SET status='COMPLETED', updated_at=NOW() WHERE id=$1", [orderId]);
}

async function poll() {
  console.log('Worker started, polling', QUEUE_URL);
  while (running) {
    try {
      const res = await sqs.send(new ReceiveMessageCommand({
        QueueUrl: QUEUE_URL,
        MaxNumberOfMessages: 5,
        WaitTimeSeconds: 10, // long polling
        VisibilityTimeout: 30,
        AttributeNames: ['ApproximateReceiveCount'],
      }));

      for (const msg of res.Messages || []) {
        const { orderId } = JSON.parse(msg.Body);
        const receives = Number(msg.Attributes?.ApproximateReceiveCount || 1);
        try {
          const { rows } = await pool.query('SELECT customer FROM orders WHERE id=$1', [orderId]);
          if (rows.length) await processOrder(orderId, rows[0].customer);
          await sqs.send(new DeleteMessageCommand({ QueueUrl: QUEUE_URL, ReceiptHandle: msg.ReceiptHandle }));
          console.log(`Order ${orderId} completed`);
        } catch (err) {
          console.error(`Order ${orderId} failed (attempt ${receives}): ${err.message}`);
          if (receives >= MAX_RECEIVES) {
            await pool.query("UPDATE orders SET status='FAILED', updated_at=NOW() WHERE id=$1", [orderId]);
          }
          // Message is NOT deleted: it reappears after the visibility timeout,
          // then moves to the DLQ after maxReceiveCount attempts.
        }
      }
    } catch (err) {
      console.error('Poll error:', err.message);
      await sleep(3000);
    }
  }
  await pool.end();
  console.log('Worker stopped');
  process.exit(0);
}

process.on('SIGTERM', () => { console.log('SIGTERM received, finishing current batch'); running = false; });
process.on('SIGINT', () => { running = false; });

poll();

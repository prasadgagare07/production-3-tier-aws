require('dotenv').config();
const express = require('express');
const path = require('path');
const AWS = require('aws-sdk');
const logger = require('./logger');
const db = require('./db');

const app = express();
const PORT = process.env.PORT || 8080;
const REGION = process.env.AWS_REGION || 'ap-south-1';
const S3_BUCKET = process.env.S3_BUCKET_NAME;

AWS.config.update({ region: REGION });
const s3 = new AWS.S3();

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

// Request logging middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    logger.info('request', {
      method: req.method,
      path: req.path,
      status: res.statusCode,
      durationMs: Date.now() - start
    });
  });
  next();
});

// --- Health check endpoint used by the ALB target group ---
// Must respond 200 quickly and WITHOUT depending on the DB, so a transient
// DB blip doesn't cause the ASG to kill healthy instances. Deep health is
// exposed separately at /api/health/deep.
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', service: 'project1-app', ts: new Date().toISOString() });
});

// Deep health check: verifies DB connectivity. Used for manual/monitoring
// checks, not wired to the ALB target group on purpose.
app.get('/api/health/deep', async (req, res) => {
  try {
    const ok = await db.checkConnection();
    res.status(200).json({ status: 'ok', database: ok ? 'connected' : 'unknown' });
  } catch (err) {
    logger.error('deep health check failed', { error: err.message });
    res.status(503).json({ status: 'error', database: 'unreachable', error: err.message });
  }
});

// Records a visit in Postgres - demonstrates EC2 -> RDS write path
app.post('/api/visits', async (req, res) => {
  try {
    const ip = req.headers['x-forwarded-for'] || req.socket.remoteAddress;
    const row = await db.recordVisit(ip);
    res.status(201).json(row);
  } catch (err) {
    logger.error('failed to record visit', { error: err.message });
    res.status(500).json({ error: 'database_error', message: 'Could not write to database' });
  }
});

// Reads visit count - demonstrates EC2 -> RDS read path
app.get('/api/visits/count', async (req, res) => {
  try {
    const count = await db.countVisits();
    res.status(200).json({ count });
  } catch (err) {
    logger.error('failed to count visits', { error: err.message });
    res.status(500).json({ error: 'database_error', message: 'Could not read from database' });
  }
});

// Demonstrates EC2 -> S3 integration: lists objects in the app bucket
app.get('/api/storage/files', async (req, res) => {
  if (!S3_BUCKET) {
    return res.status(501).json({ error: 'not_configured', message: 'S3_BUCKET_NAME not set' });
  }
  try {
    const data = await s3.listObjectsV2({ Bucket: S3_BUCKET, MaxKeys: 20 }).promise();
    res.status(200).json({ bucket: S3_BUCKET, files: data.Contents.map(o => ({ key: o.Key, size: o.Size })) });
  } catch (err) {
    logger.error('failed to list s3 objects', { error: err.message });
    res.status(500).json({ error: 's3_error', message: err.message });
  }
});

// Basic instance identity - useful to prove ALB is load balancing across
// multiple EC2 instances/AZs during failure testing
app.get('/api/instance', async (req, res) => {
  const http = require('http');
  const getMeta = (path) => new Promise((resolve) => {
    const req2 = http.get({ host: '169.254.169.254', path, timeout: 500 }, (r) => {
      let body = '';
      r.on('data', (c) => (body += c));
      r.on('end', () => resolve(body));
    });
    req2.on('error', () => resolve('unavailable'));
    req2.on('timeout', () => { req2.destroy(); resolve('unavailable'); });
  });
  const instanceId = await getMeta('/latest/meta-data/instance-id');
  const az = await getMeta('/latest/meta-data/placement/availability-zone');
  res.status(200).json({ instanceId, availabilityZone: az });
});

app.use((err, req, res, next) => {
  logger.error('unhandled error', { error: err.message, stack: err.stack });
  res.status(500).json({ error: 'internal_error' });
});

async function start() {
  try {
    await db.initSchema();
    logger.info('database schema ready');
  } catch (err) {
    // Do not crash on boot if DB isn't reachable yet - log and keep serving
    // /health so the ALB doesn't mark the instance unhealthy during RDS
    // startup races. /api/health/deep will reflect the real DB state.
    logger.error('failed to init schema at boot', { error: err.message });
  }
  app.listen(PORT, () => logger.info(`app listening on port ${PORT}`));
}

start();

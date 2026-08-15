const { Pool } = require('pg');
const logger = require('./logger');

// All values come from environment variables injected by the EC2 launch
// template (see scripts/user_data.sh + terraform/modules/compute). The DB
// password is pulled from AWS Secrets Manager at boot time, never hardcoded.
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'appdb',
  user: process.env.DB_USER || 'appuser',
  password: process.env.DB_PASSWORD,
  max: 5,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false
});

pool.on('error', (err) => {
  logger.error('Unexpected PG pool error', { error: err.message });
});

async function initSchema() {
  const sql = `
    CREATE TABLE IF NOT EXISTS visits (
      id SERIAL PRIMARY KEY,
      visited_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      source_ip TEXT
    );
  `;
  await pool.query(sql);
}

async function checkConnection() {
  const res = await pool.query('SELECT 1 AS ok');
  return res.rows[0].ok === 1;
}

async function recordVisit(ip) {
  const res = await pool.query(
    'INSERT INTO visits (source_ip) VALUES ($1) RETURNING id, visited_at',
    [ip]
  );
  return res.rows[0];
}

async function countVisits() {
  const res = await pool.query('SELECT COUNT(*)::int AS count FROM visits');
  return res.rows[0].count;
}

module.exports = { pool, initSchema, checkConnection, recordVisit, countVisits };

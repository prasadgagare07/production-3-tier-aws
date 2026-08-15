const winston = require('winston');

// CloudWatch picks up stdout/stderr automatically when the CloudWatch Agent
// is configured (see scripts/user_data.sh). We log structured JSON so it is
// queryable in CloudWatch Logs Insights.
const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  defaultMeta: { service: 'project1-app' },
  transports: [
    new winston.transports.Console()
  ]
});

module.exports = logger;

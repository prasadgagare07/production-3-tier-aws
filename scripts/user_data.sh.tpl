#!/bin/bash
set -euo pipefail
exec > >(tee /var/log/user-data.log | logger -t user-data) 2>&1

# --- OS packages ---
dnf update -y
dnf install -y amazon-cloudwatch-agent nodejs npm git jq

# --- Fetch DB credentials from Secrets Manager (never hardcoded) ---
SECRET_JSON=$(aws secretsmanager get-secret-value \
  --secret-id "${db_secret_arn}" \
  --region "${aws_region}" \
  --query SecretString --output text)

DB_USER=$(echo "$SECRET_JSON" | jq -r .username)
DB_PASSWORD=$(echo "$SECRET_JSON" | jq -r .password)
DB_NAME=$(echo "$SECRET_JSON" | jq -r .dbname)

# --- App deployment ---
mkdir -p /opt/app
cd /opt/app
# In real CI/CD, GitHub Actions rsyncs the /app folder here via SSM.
# This bootstrap only prepares the environment file and systemd service;
# the deploy workflow (.github/workflows/deploy.yml) pushes the code.

cat > /opt/app/.env << ENV
PORT=8080
AWS_REGION=${aws_region}
DB_HOST=${db_host}
DB_PORT=5432
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_SSL=true
S3_BUCKET_NAME=${s3_bucket_name}
LOG_LEVEL=info
ENV

cat > /etc/systemd/system/project1-app.service << 'UNIT'
[Unit]
Description=Project 1 App
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/app
EnvironmentFile=/opt/app/.env
ExecStart=/usr/bin/node /opt/app/server.js
Restart=always
RestartSec=5
User=ec2-user

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable project1-app.service

# --- CloudWatch Agent: ship app + system logs, EC2 detailed metrics ---
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CWA'
{
  "agent": { "metrics_collection_interval": 60 },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/user-data.log",
            "log_group_name": "/${project_name}/ec2/bootstrap",
            "log_stream_name": "{instance_id}"
          }
        ]
      }
    }
  },
  "metrics": {
    "metrics_collected": {
      "mem": { "measurement": ["mem_used_percent"] },
      "disk": { "measurement": ["used_percent"], "resources": ["/"] }
    }
  }
}
CWA

systemctl enable amazon-cloudwatch-agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# App code + npm install is pushed by the deploy workflow via SSM
# (see .github/workflows/deploy.yml + scripts/deploy.sh). Once code lands
# in /opt/app, the workflow runs `npm ci` and `systemctl restart project1-app`.

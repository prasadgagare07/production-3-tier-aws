#!/bin/bash
# Deploys the app bundle to every running instance in the ASG using
# SSM Send-Command (no SSH). Called from .github/workflows/deploy.yml.
#
# Usage: deploy.sh <asg_name> <s3_bucket> <git_sha> <aws_region>
set -euo pipefail

ASG_NAME="$1"
S3_BUCKET="$2"
SHA="$3"
REGION="$4"

INSTANCE_IDS=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "$ASG_NAME" \
  --region "$REGION" \
  --query "AutoScalingGroups[0].Instances[?LifecycleState=='InService'].InstanceId" \
  --output text)

if [ -z "$INSTANCE_IDS" ]; then
  echo "No InService instances found in $ASG_NAME - nothing to deploy to."
  exit 1
fi

echo "Deploying commit $SHA to instances: $INSTANCE_IDS"

COMMAND_ID=$(aws ssm send-command \
  --region "$REGION" \
  --document-name "AWS-RunShellScript" \
  --targets "Key=InstanceIds,Values=$(echo $INSTANCE_IDS | tr ' ' ',')" \
  --parameters "commands=[
    'aws s3 cp s3://${S3_BUCKET}/deploys/app-${SHA}.tar.gz /tmp/app.tar.gz --region ${REGION}',
    'sudo mkdir -p /opt/app',
    'sudo tar -xzf /tmp/app.tar.gz -C /opt/app --overwrite',
    'cd /opt/app && sudo npm ci --omit=dev',
    'sudo systemctl restart project1-app',
    'sleep 3',
    'curl -sf http://localhost:8080/health || (echo DEPLOY_HEALTHCHECK_FAILED && exit 1)'
  ]" \
  --query "Command.CommandId" --output text)

echo "SSM command sent: $COMMAND_ID - waiting for completion..."
aws ssm wait command-executed --command-id "$COMMAND_ID" --instance-id "$(echo $INSTANCE_IDS | cut -d' ' -f1)" --region "$REGION" || true

aws ssm list-command-invocations \
  --command-id "$COMMAND_ID" \
  --region "$REGION" \
  --details \
  --query "CommandInvocations[].{Instance:InstanceId,Status:Status}" \
  --output table

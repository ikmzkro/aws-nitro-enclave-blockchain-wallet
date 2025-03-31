#!/usr/bin/env bash
set -e
set +x

ASG_NAME="$1"
REGION="${CDK_DEPLOY_REGION:-us-east-1}"

if [[ -z "$ASG_NAME" ]]; then
  echo "[ERROR] Auto Scaling Group name is required as the first argument." >&2
  exit 1
fi

# 🔥 ログは stderr に出す！
echo "[INFO] Looking up ASG: $ASG_NAME in region: $REGION" >&2

# 🔥 結果（Instance ID）は stdout に流す
aws autoscaling describe-auto-scaling-groups \
  --region "$REGION" \
  --auto-scaling-group-name "$ASG_NAME" |
  jq -r '.AutoScalingGroups[0].Instances[] | select(.LifecycleState | contains("InService")) | .InstanceId'

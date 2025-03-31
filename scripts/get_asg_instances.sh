#!/usr/bin/env bash
set -e
set +x

# 第1引数から Auto Scaling Group 名を取得。
ASG_NAME="$1"
# 環境変数 CDK_DEPLOY_REGION を使う。なければ us-east-1 にフォールバック。
REGION="${CDK_DEPLOY_REGION:-us-east-1}"

# 引数（ASG名）が渡されていなければエラーメッセージを表示して終了。
# >&2 によりメッセージは 標準エラー出力（stderr） に出される。
if [[ -z "$ASG_NAME" ]]; then
  echo "[ERROR] Auto Scaling Group name is required as the first argument." >&2
  exit 1
fi

# スクリプトの呼び出し元に影響しないように >&2 を使う
echo "[INFO] Looking up ASG: $ASG_NAME in region: $REGION" >&2

# 🔥 結果（Instance ID）は stdout に流す
# aws autoscaling describe-auto-scaling-groups を使って、 指定したASGに紐づくインスタンス情報を取得
# 指定した Auto Scaling Group に紐づいていて、稼働中（InService）の EC2インスタンスのIDを出力する
# aws autoscaling describe-auto-scaling-groups \
#   --region "$REGION" \
#   --auto-scaling-group-name "$ASG_NAME" |
#   jq -r '.AutoScalingGroups[0].Instances[] | select(.LifecycleState | contains("InService")) | .InstanceId'

aws autoscaling describe-auto-scaling-groups \
  --region "$REGION" \
  --auto-scaling-group-name "$ASG_NAME" \
  --output json > asg_response.json

# jq -r '.AutoScalingGroups[0].Instances[] | select(.LifecycleState | contains("InService")) | .InstanceId' asg_response.json

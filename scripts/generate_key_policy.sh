#!/usr/bin/env bash
#  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#  SPDX-License-Identifier: MIT-0
set -e
set +x

# ファイル名を第一引数から受け取る
output=${1}

echo "[INFO] Using JSON file: $output"
echo "[INFO] --- JSON Content Start ---"
cat "$output"
echo "[INFO] --- JSON Content End ---"

# output.json から ASG 名を取得
# instance id
asg_name=$(jq -r '.devNitroWalletEth.ASGGroupName' "${output}")

if [[ -z "$asg_name" || "$asg_name" == "null" ]]; then
  echo "[ERROR] Failed to extract ASGGroupName from ${output}"
  exit 1
fi

echo "[INFO] Extracted ASG Name: $asg_name"

instance_id=$(./scripts/get_asg_instances.sh "${asg_name}" | head -n 1)

echo "[INFO] First instance ID in ASG: $instance_id"

# pcr_0
# pcr_0 for debug mode:
# 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
# TODO: BugFix: parse error: Invalid numeric literal at line 1, column 8
pcr_0=$(./scripts/get_pcr0.sh "${instance_id}")
echo "[INFO] pcr_0: $pcr_0"

# ec2 role
ec2_role_arn=$(jq -r '.devNitroWalletEth.EC2InstanceRoleARN' "${output}")
echo "[INFO] ec2_role_arn: $ec2_role_arn"

# lambda role
lambda_execution_arn=$(jq -r '.devNitroWalletEth.LambdaExecutionRoleARN' "${output}")
echo "[INFO] lambda_execution_arn: $lambda_execution_arn"

# account
account_id=$(aws sts get-caller-identity --output json | jq -r '.Account')

# Use the jq --arg option to pass shell variables into jq
jq --arg pcr_0 "$pcr_0" \
   --arg ec2_role_arn "$ec2_role_arn" \
   --arg lambda_execution_arn "$lambda_execution_arn" \
   --arg account_id "arn:aws:iam::${account_id}:root" \
   '
   .Statement[0].Condition.StringEqualsIgnoreCase."kms:RecipientAttestation:ImageSha384" = $pcr_0 |
   .Statement[0].Principal.AWS = $ec2_role_arn |
  .Statement[1].Principal.AWS = $lambda_execution_arn |
   .Statement[2].Principal.AWS = $account_id
   ' ./scripts/kms_key_policy_template.json

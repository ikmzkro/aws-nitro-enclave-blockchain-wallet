#!/usr/bin/env bash
#  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#  SPDX-License-Identifier: MIT-0

set +x
set -e

INSTANCE_ID=${1}

echo "[INFO] Getting PCR0 from instance: $INSTANCE_ID"

# 一時ファイルにレスポンスを保存
SSM_RESPONSE_FILE="./ssm_response.json"

# 指定した EC2 インスタンス上で Nitro Enclave を構成している場合に、
# その Enclave の PCR0（Platform Configuration Register 0）値 を取得して、
# ホストの整合性（＝セキュリティや信頼性の担保）を検証するために使用
# Nitro Enclaves が起動時に自動で生成するハッシュ値の1つで、EnclaveのDNA（構成・状態）の指紋🧬

# SSM Agent（EC2 に入ってるデーモン）経由で、EC2インスタンスにリモートでコマンドを実行するAPI
# AWS Systems Manager（略して SSM）は、
# EC2 インスタンスなどにログインせずに、
# AWS CLI からコマンドを 「リモート実行」 できるサービス
# send-command はその中の API の1つ
# parameters commands=EC2インスタンスの中でこのコマンドを実行して

aws ssm send-command \
  --region ${CDK_DEPLOY_REGION} \
  --document-name "AWS-RunShellScript" \
  --instance-ids ${INSTANCE_ID} \
  --parameters '{"commands":["sudo nitro-cli describe-enclaves | jq -r \".[].Measurements.PCR0\""]}' \
  > ${SSM_RESPONSE_FILE}

echo "[DEBUG] Raw SSM send-command response:"
cat ${SSM_RESPONSE_FILE} | jq . || cat ${SSM_RESPONSE_FILE}

# Command ID を抽出
command_id=$(jq -r '.Command.CommandId' < ${SSM_RESPONSE_FILE})
echo "[INFO] Command ID: ${command_id}"

# こっちも一時ファイルに保存して確認
INVOCATION_RESPONSE_FILE="./invocation_response.json"

# pcr_0=$(aws ssm list-command-invocations \
#   --region ${CDK_DEPLOY_REGION} \
#   --instance-id ${INSTANCE_ID} \
#   --command-id ${command_id} \
#   --details \
#   | jq -r '.CommandInvocations[0].CommandPlugins[0].Output')

aws ssm list-command-invocations \
  --region ${CDK_DEPLOY_REGION} \
  --instance-id ${INSTANCE_ID} \
  --command-id ${command_id} \
  --details \
  > ${INVOCATION_RESPONSE_FILE}

echo "[DEBUG] Raw command invocation result:"
cat ${INVOCATION_RESPONSE_FILE} | jq . || cat ${INVOCATION_RESPONSE_FILE}

# PCR0 抽出（壊れてない場合のみ）
pcr_0=$(jq -r '.CommandInvocations[0].CommandPlugins[0].Output' < ${INVOCATION_RESPONSE_FILE})

echo "PCR0: ${pcr_0}"


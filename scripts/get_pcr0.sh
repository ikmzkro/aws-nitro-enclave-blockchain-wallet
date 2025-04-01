#!/usr/bin/env bash
#  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#  SPDX-License-Identifier: MIT-0

set +x
set -e

# 指定した EC2 インスタンス上で Nitro Enclave を構成している場合に、
# その Enclave の PCR0（Platform Configuration Register 0）値 を取得して、
# ホストの整合性（＝セキュリティや信頼性の担保）を検証するために使用
command_id=$(aws ssm send-command --region ${CDK_DEPLOY_REGION} --document-name "AWS-RunShellScript" --instance-ids ${1} --parameters 'commands=["sudo nitro-cli describe-enclaves | jq -r '.[].Measurements.PCR0'"]' | jq -r '.Command.CommandId')
pcr_0=$(aws ssm list-command-invocations --region ${CDK_DEPLOY_REGION} --instance-id ${1} --command-id ${command_id} --details | jq -r '.CommandInvocations[0].CommandPlugins[0].Output')
echo ${pcr_0}

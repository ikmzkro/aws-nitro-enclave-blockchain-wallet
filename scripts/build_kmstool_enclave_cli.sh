#!/usr/bin/env bash
#  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#  SPDX-License-Identifier: MIT-0

set +x
set -e

NITRO_ENCLAVE_CLI_VERSION="v0.4.3"
KMS_FOLDER="./application/${CDK_APPLICATION_TYPE}/enclave/kms"
KMSTOOL_FOLDER="./aws-nitro-enclaves-sdk-c/bin/kmstool-enclave-cli"
TARGET_PLATFORM="linux/amd64"

if [[ ! -d ${KMS_FOLDER} ]]; then
  mkdir -p ${KMS_FOLDER}
fi

# delete repo if already there or if folder exists
rm -rf "${KMS_FOLDER}/aws-nitro-enclaves-sdk-c"

cd ${KMS_FOLDER}
git clone --depth 1 --branch ${NITRO_ENCLAVE_CLI_VERSION} https://github.com/aws/aws-nitro-enclaves-sdk-c.git

# for corporate networks disable GOPROXY
# Dockerfile.al2（Amazon Linux 2用のDockerfile）に、
# GOPROXYの設定を直書きで追加して、corporate proxy 環境
# （企業ネットワーク）でもビルドできるようにする 対策をしている。
# 企業ネットワーク内 だとGoの依存パッケージ取得に失敗する可能性が高い
# 特に proxy.golang.org にアクセスできないケースでビルドが止まる
cd ./aws-nitro-enclaves-sdk-c/containers
awk 'NR==1{print; print "ARG GOPROXY=direct"} NR!=1' Dockerfile.al2 >Dockerfile.al2_new
cd ../../

cd ${KMSTOOL_FOLDER}

# 修正済みの Dockerfile.al2_new を使わせるため
# build.sh の中の Docker ビルドパスを 書き換える
# オリジナル：-f ../../containers/Dockerfile.al2
# 変更後　　：-f ../../containers/Dockerfile.al2_new --platform=linux/amd64

# sed 's|置換前|置換後|g' 対象ファイル > 新しいファイル
sed "s|-f ../../containers/Dockerfile.al2 ../..|-f ../../containers/Dockerfile.al2_new ../.. --platform=${TARGET_PLATFORM}|g" build.sh >build.sh_new
# 一時的に生成した新しい build.sh を、元の build.sh に上書きする 
mv build.sh_new build.sh
chmod +x build.sh
./build.sh

cp ./kmstool_enclave_cli ../../../kmstool_enclave_cli
cp ./libnsm.so ../../../libnsm.so

cd -

rm -rf ./aws-nitro-enclaves-sdk-c

echo "kmstool_enclave_cli build successful"

#!/usr/bin/env bash
#  Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
#  SPDX-License-Identifier: MIT-0

set +x
set -e

NITRO_ENCLAVE_CLI_VERSION="v0.4.1"
KMS_FOLDER="./application/${CDK_APPLICATION_TYPE}/enclave/kms"
KMSTOOL_FOLDER="./aws-nitro-enclaves-sdk-c/bin/kmstool-enclave-cli"
TARGET_PLATFORM="linux/amd64"

echo "[DEBUG] build.sh の内容確認"
cat ./application/${CDK_APPLICATION_TYPE}/enclave/kms/aws-nitro-enclaves-sdk-c/bin/kmstool-enclave-cli/build.sh

# 保存フォルダを作る。もし無ければ作るってだけ。
if [[ ! -d ${KMS_FOLDER} ]]; then
  mkdir -p ${KMS_FOLDER}
fi

# 前に同じものダウンロードしてたら削除（リセットする）。
rm -rf "${KMS_FOLDER}/aws-nitro-enclaves-sdk-c"

# GitHubから SDK本体 を取ってくる
cd ${KMS_FOLDER}
git clone --depth 1 --branch ${NITRO_ENCLAVE_CLI_VERSION} https://github.com/aws/aws-nitro-enclaves-sdk-c.git

# for corporate networks disable GOPROXY
# Goの依存パッケージを直接ネットから取るのではなく、
# Googleが用意してる「proxy.golang.org」経由で取得したい。
# Dockerfile.al2 の 1行目の次に ARG GOPROXY=direct という設定を追加して、
# → Dockerfile.al2_new という新しいファイルを作ってる
cd ./aws-nitro-enclaves-sdk-c/containers
awk 'NR==1{print; print "ARG GOPROXY=direct"} NR!=1' Dockerfile.al2 >Dockerfile.al2_new
cd ../../

cd ${KMSTOOL_FOLDER}

# 新しく加工したDockerfile（GOPROXY入り）を使うため。
# --platform=linux/amd64 は、M1 Macなどでも x86_64環境でビルドさせるための指定。
# build.sh の中で使ってる 古いDockerfile（al2）を新しいDockerfile（al2_new）に置き換えてる。
# さらに --platform=linux/amd64 を追加してます
sed "s|-f ../../containers/Dockerfile.al2 ../..|-f ../../containers/Dockerfile.al2_new ../.. --platform=${TARGET_PLATFORM}|g" build.sh >build.sh_new
mv build.sh_new build.sh
chmod +x build.sh
./build.sh

# 出来上がった実行ファイル（kmstool_enclave_cli）とライブラリ（libnsm.so）を上の階層にコピーしておく。
# あとで使いやすいように取り出してるだけです。
cp ./kmstool_enclave_cli ../../../kmstool_enclave_cli
cp ./libnsm.so ../../../libnsm.so

cd -

# GitHubから落としてきたフォルダ（SDK）を削除してクリーンアップしてるだけです。
rm -rf ./aws-nitro-enclaves-sdk-c

# 「おわったよー！ビルド成功！」って表示するだけです。
echo "kmstool_enclave_cli build successful"

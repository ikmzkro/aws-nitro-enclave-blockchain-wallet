
| Dockerfileのパス                                                                 | 説明 |
|----------------------------------------------------------------------------------|------|
| `application/eth1/enclave/Dockerfile`                                            | **Enclaveアプリ全体**を組み立てるDockerfile（＝最終的にAWSにデプロイされる本番イメージ） |
| `application/eth1/enclave/kms/aws-nitro-enclaves-sdk-c/containers/Dockerfile.al2_new` | **Enclave内で使うKMS CLIバイナリを作るための専用Dockerfile**（＝中間生成物ビルド用） |

### ① `Dockerfile.al2_new` は何のためにある？

👉 **「Enclave内で使うKMS CLIツール」をビルドするためだけのDockerfile**

具体的には：
- `aws-nitro-enclaves-sdk-c` というGitHub OSSにある `kmstool_enclave_cli` をビルド
- それをコンテナ内で作って、外に取り出して使う
- 完成品は `kmstool_enclave_cli`（バイナリ）と `libnsm.so`（共有ライブラリ）

---

### ② `application/eth1/enclave/Dockerfile` は何のためにある？

👉 **「アプリケーション本体（＝Enclaveが動く環境）」を構築するDockerfile**

中でやってることは：
- Enclaveで動かすPythonスクリプト（`server.py`）を入れて
- さっきビルドした `kmstool_enclave_cli` を **`COPY` で取り込んで**使う
- 最終的にはこれをEnclave Image Format（`.eif`）に変換してデプロイされる

---

## 🏗 つまり全体はこういう構成👇

```
🔧 Dockerfile.al2_new  ──→（CLIバイナリをビルド）──→  kmstool_enclave_cli, libnsm.so
　　　　　　　　　　　　　　            　　　　　　　↓（手動でコピー）
🏗 Dockerfile（enclave） ──→（Enclaveアプリ＋CLIを含めてビルド）──→ EIF（Enclave Image）
```

---

## 💡 なぜ1つのDockerfileでやらないの？

### 理由は：
- **Enclave用Dockerfileの中でCLIビルドするのはめっちゃ重いし面倒**
- **CLIバイナリだけ使えればよくて、ビルド環境は分けた方が安全・再利用できる**
- **Enclave側はシンプルで軽くしておきたい（起動も早くなる）**

まさに「**中間生成物は別環境で作って、成果物だけ使おうぜ設計**」なんです。

---

## ✅ じゃあどう覚えればいい？

### 👇この感覚だけでOK！

- `Dockerfile.al2_new` → **道具を作る工場**
- `Dockerfile`（enclave）→ **道具を持って働くアプリの家**

---

## ✍ 最後にまとめ

| Dockerfileの場所                       | やってること                                            |
|----------------------------------------|---------------------------------------------------------|
| `.../containers/Dockerfile.al2_new`    | KMS CLI（中間ツール）をビルドする                       |
| `.../enclave/Dockerfile`               | Enclaveの中で動かすアプリ全体を組み立てる              |
| なぜ分ける？                           | ビルド工程を分離して、安全・高速・再利用性を確保するため |

---

「この構成がキレイだから分かりやすい」わけじゃなくて、  
👉 むしろ**キレイだけど初見殺し**構成なので、最初は混乱して当然です。

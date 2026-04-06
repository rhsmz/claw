### 1. プロジェクトディレクトリ構造

```text
claw-rust-edition/
├── docker-compose.yml          # 更新後のDocker Composeファイル
├── .env                        # 環境変数ファイル（既存のものを使用）
├── litellm_config.yaml         # 更新後のLiteLLM設定ファイル
├── rust-inference/             # （新規作成）推論エンジン用ディレクトリ
│   ├── Dockerfile              # 推論エンジンのビルド用
│   ├── Cargo.toml              # Rustラッパーの設定ファイル
│   └── src/                    # Rustラッパーのソースコード
├── mcp/                        # MCP関連（既存のものを使用）
└── zeroclaw/                   # 帝国本体（既存のものを使用）
```

---

### 2. 推論エンジン環境の構築 (Rust + SYCL)

新設する `rust-inference` ディレクトリに、OneAPIとRust環境を構築するための `Dockerfile` を作成します。

**ファイル: `rust-inference/Dockerfile`**

```dockerfile
# OneAPI Base Toolkit 2025.3.1 をベースにする
FROM intel/oneapi-basekit:2025.3.1-devel-ubuntu22.04

# GCCとlibstdc++のバージョン不整合（GCC 13の要求など）を避けるため、新しい標準ライブラリを導入
RUN apt-get update && apt-get install -y \
    build-essential gcc-12 g++-12 ninja-build cmake curl git \
    intel-opencl-icd level-zero && \
    rm -rf /var/lib/apt/lists/*

# Rustツールチェーンのインストール
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /app

# llama.cppコアの取得とSYCLバックエンドのコンパイル
# MKL_FOUND=FALSEエラーを防ぐため /opt/intel/oneapi/ を明示してビルド
RUN git clone https://github.com/ggml-org/llama.cpp.git && \
    cd llama.cpp && \
    . /opt/intel/oneapi/setvars.sh --force && \
    cmake -B build -G "Ninja" \
      -DGGML_SYCL=ON \
      -DCMAKE_C_COMPILER=icx \
      -DCMAKE_CXX_COMPILER=icpx \
      -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build --config Release -j $(nproc)

# Rustインターフェース（rust-llama.cpp等を利用したOpenAI互換APIサーバー）のビルド
COPY ./src /app/src
COPY ./Cargo.toml /app/
RUN cargo build --release

# GGUFモデルのネイティブロードと実行制御を行うエンドポイント起動
EXPOSE 8080
CMD ["/bin/bash", "-c", "source /opt/intel/oneapi/setvars.sh && ./target/release/rust-llama-api-server --host 0.0.0.0 --port 8080 --model-dir /app/models"]
```

---

### 3. Docker Compose の完全定義

ご提示いただいたファイルをベースに、新たに `rust-inference` サービスを追加し、SYCL環境を利用するためのGPUデバイスマウントとチューニング設定を記述しています。

**ファイル: `docker-compose.yml`**

```yaml
services:
  # データベース: Context7 (RAG) とエージェントの記憶用
  postgres:
    image: ankane/pgvector:latest
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${ZEROCLAW_DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${ZEROCLAW_DB_NAME}"]
      interval: 5s
      timeout: 5s
      retries: 5

  # 高速キャッシュ: バックエンド部隊の検証用
  redis:
    image: redis:7-alpine
    command: redis-server --save 60 1 --loglevel warning

  # LLMプロキシ: コスト管理・リトライ・冗長化の要
  litellm:
    image: ghcr.io/berriai/litellm:main-latest
    volumes:
      - ./litellm_config.yaml:/app/config.yaml
    environment:
      OPENAI_API_KEY: ${OPENAI_API_KEY}
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY}
      LITELLM_MASTER_KEY: ${LITELLM_MASTER_KEY}
    ports:
      - "4000:4000"
    depends_on:
      - rust-inference

  # 新設：Rust + C++ (SYCL) ハイブリッド推論エンジン
  rust-inference:
    build: 
      context: ./rust-inference
    ports:
      - "8080:8080"
    volumes:
      # I/Oパフォーマンスを最大化するため、ホスト側のモデル配置ディレクトリをマウント
      - ~/.cache/models:/app/models
    devices:
      # Intel GPU（SYCLバックエンド）の認識用
      - /dev/dri:/dev/dri
    environment:
      # CPU側のストールを削減し、GPU稼働率を高めるSYCL特有のチューニング
      - CUDA_SCALE_LAUNCH_QUEUES=4x

  # MCP Gateway: 39のスキル（神器）を統合するハブ
  mcp-gateway:
    image: mcp/gateway:latest
    volumes:
      - ./mcp/config.json:/app/config.json
      - ./mcp/vault:/app/vault:ro # 機密情報
    environment:
      - BRAVE_SEARCH_API_KEY=${BRAVE_SEARCH_API_KEY}
      - GITHUB_PERSONAL_ACCESS_TOKEN=${GITHUB_PAT}
      - AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY}
      - AWS_SECRET_ACCESS_KEY=${AWS_SECRET_KEY}
    depends_on:
      postgres:
        condition: service_healthy

  # ZeroClaw Server: 帝国の本体
  zeroclaw:
    build: .
    volumes:
      - ./config.toml:/app/config.toml
      - ./prompts:/app/prompts
      - ./skills:/app/skills
    environment:
      - LITELLM_MASTER_KEY=${LITELLM_MASTER_KEY}
      - POSTGRES_USER=${POSTGRES_USER}
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    ports:
      - "42617:42617"
    depends_on:
      - mcp-gateway
      - litellm

volumes:
  postgres_data:
```

---

### 4. LiteLLM の完全な設定

ご提示いただいたファイルをベースに、Ollamaへの接続を **Rustハイブリッド推論エンジンのOpenAI互換エンドポイント（`http://rust-inference:8080/v1`）** へルーティングするように完全に書き換えました。

**ファイル: `litellm_config.yaml`**

```yaml
# =============================================================================
# LiteLLM Configuration - The Sovereign 64 (Imperial Communication Hub)
# =============================================================================

model_list:
  # ---------------------------------------------------------------------------
  # 1. バニラ設定: ローカル推論エンジン (Rust + llama.cpp SYCL ハイブリッド)
  # ---------------------------------------------------------------------------
  # 帝国の標準OS。コストゼロで24時間稼働する基幹モデル。
  
  - model_name: imperial-logic-high-v1  # 指揮官・アーキテクト・法務用
    litellm_params:
      model: openai/gemma3:12b  # OpenAI API互換として扱う
      api_base: http://rust-inference:8080/v1
      api_key: dummy-key # OpenAI互換サーバー用のダミーキー
      timeout: 300
      tpm: 100000
      rpm: 1000

  - model_name: imperial-build-knight-v1 # 開発部隊・ウィザード用
    litellm_params:
      model: openai/gemma3:12b
      api_base: http://rust-inference:8080/v1
      api_key: dummy-key
      timeout: 600

  - model_name: imperial-scout-mini-v1  # 調査・諜報・サポート・文書生成用
    litellm_params:
      model: openai/gemma3:12b
      api_base: http://rust-inference:8080/v1
      api_key: dummy-key
      timeout: 120

  # ---------------------------------------------------------------------------
  # 2. 追加設定: クラウドLLM (必要に応じてコメントアウトを解除して有効化)
  # ---------------------------------------------------------------------------
  # 極めて複雑な論理推論や、大規模なコード生成が必要な場合に切り替えます。

  # --- OpenAI Stack ---
  # - model_name: imperial-logic-high-v1
  #   litellm_params:
  #     model: openai/gpt-4o
  #     api_key: os.environ/OPENAI_API_KEY
  #     rpm: 500

  # - model_name: imperial-scout-mini-v1
  #   litellm_params:
  #     model: openai/gpt-4o-mini
  #     api_key: os.environ/OPENAI_API_KEY

  # --- Anthropic Stack ---
  # - model_name: imperial-build-knight-v1
  #   litellm_params:
  #     model: anthropic/claude-3-5-sonnet-20240620
  #     api_key: os.environ/ANTHROPIC_API_KEY
  #     rpm: 200

# =============================================================================
# ルーティング & フォールバック設定
# =============================================================================

router_settings:
  # 負荷ベースのルーティング。複数のローカルインスタンスがある場合に有効。
  routing_strategy: usage-based-routing-v2 
  
  # ローカルモデルがタイムアウトしたりエラーを吐いた際の救済策。
  enable_fallbacks: true
  context_window_fallbacks:
    - [.*, openai/gpt-4o] # コンテキスト溢れ時はクラウドへ逃がす設定例
  
  # エラー発生時の自動リトライ設定
  num_retries: 3
  retry_after: 5
  set_verbose: false

# =============================================================================
# グローバル設定
# =============================================================================

general_settings:
  # config.toml の [llm] セクションからの認証に使用。
  master_key: os.environ/LITELLM_MASTER_KEY 
  
  # 実行統計・トークン消費量を記録。
  database_url: os.environ/POSTGRES_URL 
  store_model_usage: true

litellm_settings:
  # 推論結果をキャッシュして応答を高速化し、トークンを節約。
  cache: true
  cache_type: redis
  
  # 未知のパラメータが送られてきてもエラーにせず無視する。
  drop_params: true
  
  # 可観測性ツール（Langfuse）との連携設定
  success_callback: ["langfuse"]
  failure_callback: ["langfuse"]

# =============================================================================
# 監査・セキュリティ設定
# =============================================================================
# セキュリティ監査部（The INTEL Pod）がログを収集しやすくするための設定。

# ユーザーID（クルー名）をメタデータとして付与し、誰がどのモデルを叩いたか追跡。
metadata:
  project: "zeroclaw-enterprise"
  tier: "sovereign-64"
```

---

## 実装メモ（本リポジトリ `adbx-claw` との整合）

- ディレクトリ名は Plan の `claw-rust-edition` ではなく **既存リポジトリルート**のまま運用する。
- **`docker-compose.yml`** は Plan の簡略版への全面置換はせず、既存の postgres-init / Langfuse / Open WebUI / Stack Portal 等を維持したうえで **`rust-inference` を追加し Ollama を削除**した。
- 推論プロセスは Plan 記載の `rust-llama-api-server` ではなく、**llama.cpp 公式 SYCL 手順に沿ってビルドした `llama-server`（OpenAI 互換 HTTP）**を `entrypoint.sh` で起動する（`rust-inference/` に Cargo スタブを同梱し、将来の Rust ラッパー用に置いた）。
- LiteLLM の **`enable_fallbacks` / `context_window_fallbacks`** は現行イメージの Router と齟齬があり得るため **採用していない**。
- **ホスト公開ポート**は Open WebUI の `:8080` とぶつからないよう **`RUST_INFERENCE_HOST_PORT`（既定 9080）** とした（サービス間は従来どおり `rust-inference:8080`）。
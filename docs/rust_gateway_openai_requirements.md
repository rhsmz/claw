# Phase 0: OpenAI 互換 API 要件（ZeroClaw / Open WebUI / 周辺クライアント）

本ドキュメントは [TASKS_RUST_FIRST_STACK.md](../TASKS_RUST_FIRST_STACK.md)（リポジトリルート）Phase 0 の成果物です。LiteLLM を外す・薄くする前提で、**必須エンドポイント**と **Python LiteLLM 固有機能の要否**を整理します。

## 1. クライアント別に使う HTTP API

### 1.1 ZeroClaw（`zeroclaw/config.toml` / 公式イメージ）

| 項目 | 内容 |
|------|------|
| ベース URL | 例: `http://litellm:4000/v1` → Rust ゲートウェイ試験時は `http://llm-gateway-rust:4100/v1` |
| 認証 | `Authorization: Bearer ${LITELLM_MASTER_KEY}`（`API_KEY` / `OPENAI_API_KEY` と同一値） |
| 想定 API | **チャット補完**（OpenAI SDK 互換）。典型的には `POST /v1/chat/completions`。 |
| モデル名 | `.env` の `DEFAULT_MODEL` = `litellm_config.yaml` の `model_name`（例: `imperial-logic-high-v1`）。ゲートウェイ側で **表示名 → llama-server が受け付ける `model` 文字列**へ書き換えが必要。 |

**補足**: ZeroClaw の詳細なエンドポイント一覧はイメージ内実装に依存するが、本スタックでは **OpenAI 互換 `/v1` プロキシ**があれば足りる構成としてよい。

### 1.2 Open WebUI（`--profile ui`）

| 項目 | 内容 |
|------|------|
| 環境変数 | `OPENAI_API_BASE_URL` = `http://litellm:4000/v1`、`OPENAI_API_KEY` = `LITELLM_MASTER_KEY` |
| 想定 API | `GET /v1/models`（モデル一覧）、`POST /v1/chat/completions`（**ストリーミング含む**）、RAG・機能によっては `POST /v1/embeddings` |
| 備考 | UI はストリーミング応答を前提とすることが多い。**ゲートウェイはレスポンスボディのストリーミング転送**が必要。 |

### 1.3 `scripts/management`（Rust CLI・ナレッジ同期）

| 項目 | 内容 |
|------|------|
| 既定 URL | `IMPERIAL_LITELLM_URL` または `http://127.0.0.1:4000` |
| 使用 API | `POST /v1/embeddings`（`LITELLM_MASTER_KEY` を Bearer に使用） |
| Rust ゲートウェイのみの場合 | llama-server が **埋め込み API** を公開していればプロキシで転送可能。未対応なら **LiteLLM を残す**か、**別埋め込みサービス**が必要。 |

### 1.4 rust-inference（llama-server）直接

| 項目 | 内容 |
|------|------|
| ベース | `http://rust-inference:8080/v1` |
| モデルパラメータ | `litellm_config.yaml` では `openai/gpt-3.5-turbo` を指定して OpenAI 互換として扱っている。 |

## 2. エンドポイント優先度（Rust ゲートウェイ MVP）

| 優先度 | メソッド | パス | 用途 |
|--------|----------|------|------|
| P0 | POST | `/v1/chat/completions` | ZeroClaw / Open WebUI の中核 |
| P0 | GET | `/v1/models` | Open WebUI のモデル選択（エイリアスを返す実装が現実的） |
| P1 | POST | `/v1/embeddings` | management CLI・RAG（上流が対応している場合のみ転送） |
| P2 | * | その他 `/v1/*` | 必要に応じて透過プロキシ |

## 3. Python LiteLLM 依存機能の要否（本リポジトリ構成）

| 機能 | 設定・実装 | 要否 | メモ |
|------|------------|------|------|
| モデルルーティング | `litellm_config.yaml` の `model_list` | **要（同等の別手段）** | 表示名とバックエンドモデル名の対応をゲートウェイまたは設定で再現。 |
| PostgreSQL（利用記録等） | `general_settings.database_url` | **任意** | 監査・課金が不要なら Rust ゲートウェイでは省略可。 |
| Redis キャッシュ | `litellm_settings.cache` | **任意** | ローカル単体では無効化しても可。 |
| マスターキー | `LITELLM_MASTER_KEY` | **要（慣習）** | クライアントが Bearer で送っている。**Rust ゲートウェイでも同じキー検証**で互換。 |
| Langfuse コールバック | `success_callback` 等 | **任意** | 現状 `[]`。有効化するなら LiteLLM 継続か、別経路（OTel 等）を検討。 |

## 4. litellm-rs 公式ゲートウェイ（Phase 1 調査メモ）

- 起動: `cargo install litellm-rs --bin gateway` ＋ `config/gateway.yaml`（[gateway.yaml.example](https://github.com/majiayu000/litellm-rs/blob/main/config/gateway.yaml.example)）。
- OpenAI プロバイダの **`base_url`** を `http://rust-inference:8080/v1` にし、`api_key` をダミーにすれば **理論上は** llama-server へ集約可能。
- 公式 Docker イメージは README に無いため、**本リポジトリでは先行して軽量プロキシ `llm-gateway-proxy/` を追加**し、Compose profile `rust-gateway` で PoC 可能にした。

## 5. ブラウザでの検証（スタック起動後・開発時）

**前提**: Docker スタックがホストのポートにバインドされていること（または `task llm-gateway-dev` でプロキシのみローカル起動）。

| 順序 | URL（既定） | 期待 |
|------|-------------|------|
| 1 | `http://localhost:8042/` | **スタックポータル**が表示され、各サービスへのカードが並ぶ |
| 2 | ポータルから **Rust 薄型 LLM ゲートウェイ** または直接 `http://localhost:4100/health` | 本文が **`ok`**（200）。未起動時は接続エラー |
| 3 | （任意）`http://localhost:4000/` | LiteLLM UI（コア `task up` 時） |
| 4 | （任意）`http://localhost:8080/` | Open WebUI（`--profile ui` 時）。Rust ゲートウェイ試験時は管理画面で API のベース URL を `http://llm-gateway-rust:4100/v1` に変更 |

**ローカル単体（Docker なし）**: `task llm-gateway-dev` で `llm-gateway-proxy` を起動し、ブラウザで `http://127.0.0.1:4100/health` を開く。上流 `rust-inference` が無い場合でも **ヘルスだけ**確認できる（チャットは 502 になる）。

**Cursor ブラウザ MCP**: タブが既にある場合は操作前にロックし、ナビゲート後にスナップショットで URL を確認する。プレーンテキストの `ok` はアクセシビリティツリーに出ないことがあるため、**開発者ツールの Network** または **curl** と併用するとよい。

**自動スモーク**: `scripts/stack-smoke-test.ps1` / `stack-smoke-test.sh` は **コア**（ポータル・LiteLLM・rust-inference・MCP）を必須。**profile 系**（llm-gateway-rust・ZeroClaw・Llumen・Open WebUI・Langfuse）は既定では未起動でも **SKIP** して `task test-smoke` を成功させられる。全件必須にする場合は **`task test-smoke-strict`** または `STACK_SMOKE_STRICT=1`。ポートは `LLUMEN_HOST_PORT` / `LLM_GATEWAY_RUST_HOST_PORT` 等で上書き可。

**ユニットテスト**: `llm-gateway-proxy` は `cargo test`（`task test` に含む）で URL 組み立て・モデル書き換え・Bearer 検証を検証する。

## 6. Phase 3 — Llumen（軽量 Rust UI）

- **Compose**: サービス `llumen`、`profiles: ["ui-llumen"]`、イメージ `ghcr.io/pinkfuwa/llumen:latest`。
- **起動**: コア（`task up`）のあと **`task up-with-llumen`** または `docker compose --profile ui-llumen up -d --wait`。
- **接続先**: 既定 `LLUMEN_OPENAI_BASE=http://litellm:4000/v1`。Rust 薄型ゲートウェイを使う場合は `http://llm-gateway-rust:4100/v1` とし、**`--profile rust-gateway` も有効化**すること（`depends_on` は LiteLLM のままなので、LiteLLM 無し運用は別途オーバーライドが必要）。
- **認証**: コンテナへは `API_KEY=${LITELLM_MASTER_KEY}` を渡す。UI の初回ログインは [llumen README](https://github.com/pinkfuwa/llumen) の記載に従う。
- **Erato**: 公式リポジトリは **private submodule** 前提のため、本スタックには **未同梱**。必要なら別リポジトリで Helm / ソースから構築する。

## 7. 関連ファイル

- `docker-compose.yml` … `llm-gateway-rust`（`--profile rust-gateway`）、`llumen`（`--profile ui-llumen`）
- `llm-gateway-proxy/` … 最小 Axum プロキシ
- [ENV.md](../ENV.md) … `LLM_GATEWAY_RUST_*` / `LLUMEN_*` 変数
- `stack-portal/index.html` … ゲートウェイ・Llumen へのジャンプリンク

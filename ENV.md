# 環境変数と MCP 連携（`.env` / `mcp/gateway.env`）

プロジェクト全体の秘密情報・接続情報は主に **ルートの `.env`** に置きます。MCP ツール向けの変数は **`mcp/gateway.env.example`** をテンプレートにした `mcp/gateway.env` にまとめる運用を推奨します（`task setup` または WSL/Linux では **`task setup-wsl`** で両方の雛形がコピーされます）。

スタックの全体像・起動手順は [README.md](README.md)、MCP ゲートウェイとスキル対応の詳細は [mcp/README.md](mcp/README.md) を参照してください。

---

## 1. ルート `.env`（Docker Compose / Task / 各サービス）

Docker Compose V2 は、**プロジェクトルートの `.env`** を自動的に読み込み、`docker-compose.yml` 内の `${VAR}` 補間に使います。`Taskfile.yml` も `dotenv: ['.env']` で同じファイルを参照します。

WSL で **`error getting credentials`** が出る場合は **`task docker-wsl-fix-creds-store`**（`~/.docker/config.json` のバックアップと `credsStore` 除去）。詳細は [README.md](README.md) のトラブルシューティング。

初回は次で作成します。

```bash
cp .env.example .env
```

Windows（cmd）の例: `copy .env.example .env`

または `task setup` / WSL では **`task setup-wsl`**（`.env` と `mcp/gateway.env` の雛形作成・ディレクトリ準備を含む。後者は PowerShell を呼ばない）。

### 1.1 `.env.example` に基づく変数一覧

| 区分 | 変数名 | 用途 |
|------|--------|------|
| ZeroClaw | `ZEROCLAW_PORT` | ZeroClaw の待受ポート（既定例） |
| | `ZEROCLAW_LOG_LEVEL` | ログレベル |
| | `ZEROCLAW_AUDIT_LOG` | 監査ログの有効化 |
| | `ZEROCLAW_DB_NAME` | PostgreSQL 上の DB 名（Compose の `POSTGRES_DB` と一致させる） |
| LLM | `LITELLM_MASTER_KEY` | LiteLLM のマスターキー（ZeroClaw の `API_KEY` 等と揃える） |
| | `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GOOGLE_API_KEY` / `MISTRAL_API_KEY` | クラウドプロバイダ利用時 |
| | `DEFAULT_MODEL` / `FALLBACK_MODEL` | 既定・フォールバックモデル（`litellm_config.yaml` の `model_name` と整合） |
| | `RUST_INFERENCE_MODELS_DIR` | `rust-inference` / `opencl-inference` にマウントする GGUF 置き場（既定 `./storage/rust-inference-models`） |
| | `RUST_INFERENCE_HOST_PORT` | ホストから SYCL llama-server を叩くポート（既定 `9080`） |
| | `OPENCL_INFERENCE_HOST_PORT` | **`--profile opencl-wsl`** 時の OpenCL llama-server ホストポート（既定 `9081`）。Compose は **`/usr/lib/wsl` ツリー**と **`/dev/dxg`** を渡す（Intel [compute-runtime#625](https://github.com/intel/compute-runtime/issues/625)）。`/dev/dri` は vgem 等で用意（`task wsl-setup-gpu`） |
| | `RUST_INFERENCE_ONEAPI_VERSION` / `LLAMA_CPP_REF` / `GGML_SYCL_F16` / `RUST_INFERENCE_KEEP_SYCL` | `rust-inference` イメージのビルド引数（`RUST_INFERENCE_KEEP_SYCL=1` で SYCL プラグインを残す。通常は GPU 用 compose オーバーライドで指定） |
| | `LLM_GATEWAY_RUST_HOST_PORT` | **`--profile rust-gateway`** 時の `llm-gateway-rust` ホスト公開ポート（既定 `4100`）。詳細は [docs/rust_gateway_openai_requirements.md](docs/rust_gateway_openai_requirements.md) |
| | `ONEAPI_DEVICE_SELECTOR` | oneAPI ランタイムのデバイス選択（**空にしない**。例: `level_zero:gpu`（Arc）、不調時は `opencl:gpu`） |
| | `COMPOSE_FILE` | （任意）WSL 向け GPU オーバーライドを既定化する場合のファイル列（区切りは Linux/WSL で `:`、Windows ホストの `.env` では `;`）。`task rust-inference-gpu-wsl` と同じ組み合わせに揃える |
| | `LLAMA_MODEL_PATH` / `N_GPU_LAYERS` / `LLAMA_EXTRA_ARGS` | コンテナ内 `llama-server` の挙動調整（任意） |
| | `RUST_INFERENCE_DISABLE_SYCL_PLUGIN` | **`docker-compose.rust-inference-gpu-wsl.yml` 併用時**: `1` で `libggml-sycl` を外し **CPU のみ**（大型モデル + iGPU で SYCL 確保失敗する場合の既定）。SYCL GPU を試すとき `0` |
| | `RUST_INFERENCE_GPU_WSL_NGL` | 同上 compose の `N_GPU_LAYERS`（未設定 **`-1`**。`.env` の `N_GPU_LAYERS` はこのファイルでは使わない） |
| | `RUST_INFERENCE_WSL_ONEAPI_DEVICE` | 同上の `ONEAPI_DEVICE_SELECTOR`（未設定 **`opencl:gpu`**） |
| DB / キャッシュ | `POSTGRES_USER` / `POSTGRES_PASSWORD` / `POSTGRES_HOST` / `POSTGRES_PORT` | DB 接続（Compose 内ホスト名は `postgres`、コンテナ内ポートは常に `5432`） |
| | `POSTGRES_HOST_PORT` | **ホストへ公開する** Postgres ポート（既定 `5432`。ホストで 5432 が使用中なら `5433` など） |
| | `REDIS_URL` | Redis 接続 URL |
| GitHub | `GITHUB_PAT` | **MCP GitHub サーバ用**: Compose が `mcp-gateway` に `GITHUB_PERSONAL_ACCESS_TOKEN` として渡す |
| | `GITHUB_ORG` | 組織スコープの操作時 |
| 検索 | `BRAVE_SEARCH_API_KEY` | Brave Search（MCP 経由） |
| | `ARXIV_USER_ID` | Arxiv の任意識別子（レート緩和など） |
| ナレッジ | `CONTEXT7_API_KEY` | Context7 MCP |
| 品質 | `BROWSERBASE_API_KEY` / `BROWSERBASE_PROJECT_ID` | Browserbase |
| | `SENTRY_AUTH_TOKEN` / `SENTRY_ORG` / `SENTRY_PROJECT` | Sentry |
| セキュリティ | `SNYK_TOKEN` | Snyk |
| | `VAULT_ADDR` / `VAULT_TOKEN` | HashiCorp Vault |
| | `LEGAL_DB_API_KEY` | 法務 DB API（契約がある場合） |
| クラウド / K8s | `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` | AWS（`mcp-gateway` にも渡す） |
| | `KUBECONFIG_PATH` | kubeconfig の参照パス（運用に合わせて） |
| 連携 | `DISCORD_WEBHOOK_URL` / `SLACK_BOT_TOKEN` / `SLACK_CHANNEL_ID` | 通知 |
| | `NOTION_API_KEY` / `NOTION_DATABASE_ID` | Notion（任意: 一度ローカルへ export する場合） |
| | `CONFLUENCE_API_TOKEN` / `CONFLUENCE_EMAIL` / `CONFLUENCE_URL` | Confluence（任意: 一度ローカルへ export する場合） |
| 多言語サンドボックス | `COMPOSER_AUTH` / `CARGO_HOME` / `GOPATH` / `NODE_ENV` | ビルド・実行環境 |
| Stack Portal | `STACK_PORTAL_PORT` | 静的ポータル（`stack-portal/`）のホスト公開ポート（既定 `8042`） |
| Llumen（`--profile ui-llumen`） | `LLUMEN_HOST_PORT` | ホスト公開ポート（既定 `8079`。コンテナ内は `80`） |
| | `LLUMEN_OPENAI_BASE` | OpenAI 互換 API のベース URL（既定 `http://litellm:4000/v1`。Rust ゲートウェイなら `http://llm-gateway-rust:4100/v1`） |

**GitHub トークン名の対応**: `mcp/config.json` や `mcp/gateway.env.example` では `GITHUB_PERSONAL_ACCESS_TOKEN` という名前が使われます。ルート `.env` では **`GITHUB_PAT`** を設定し、Compose が MCP Gateway コンテナ内では `GITHUB_PERSONAL_ACCESS_TOKEN` として渡します。`mcp/gateway.env` に直接書く場合は **`GITHUB_PERSONAL_ACCESS_TOKEN`** で統一してください。

---

## 2. `mcp/gateway.env`（MCP 向けの整理用テンプレート）

`mcp/gateway.env.example` を `mcp/gateway.env` にコピーして編集します（`.gitignore` 済み）。

| 区分 | 主な変数 | 用途 |
|------|----------|------|
| 検索 | `BRAVE_SEARCH_API_KEY` / `GOOGLE_MAPS_API_KEY` | Brave / 地図（任意） |
| 開発 | `GITHUB_PERSONAL_ACCESS_TOKEN` / `GITLAB_PERSONAL_ACCESS_TOKEN` | リポジトリ操作 |
| パッケージ | `NPM_TOKEN` / `COMPOSER_AUTH_JSON` | プライベートレジストリ |
| ナレッジ | `CONTEXT7_API_KEY` / `NOTION_*` / `CONFLUENCE_*` | ドキュメント・Wiki |
| 品質 | `SENTRY_*` / `BROWSERBASE_*` / `SNYK_TOKEN` | 監視・UI・脆弱性 |
| セキュリティ | `VAULT_ADDR` / `VAULT_TOKEN` | Vault |
| インフラ | `AWS_*` / `KUBECONFIG` | クラウド・Kubernetes |
| 連携 | `DISCORD_WEBHOOK_URL` / `SLACK_BOT_TOKEN` / `SLACK_APP_TOKEN` | チャット |
| DB | `POSTGRES_URL` / `REDIS_URL` | MCP サーバが直接 DB に触る場合の接続文字列 |

**Compose との関係（重要）**: 現行の `docker-compose.yml` では、`mcp-gateway` サービスに **`mcp/gateway.env` を `env_file` でマウントしていません**。ゲートウェイコンテナへ渡る環境変数は、ファイル内の **`environment:` ブロックで明示したもの**と、ルート `.env` からの補間のみです。追加の MCP サーバ用シークレットをゲートウェイで使う場合は、(1) ルート `.env` に同名変数を置き `docker-compose.yml` の `mcp-gateway.environment` に追記する、または (2) `env_file: mcp/gateway.env` を `mcp-gateway` に追加する、のいずれかが必要です。詳細は [mcp/README.md](mcp/README.md) の「ゲートウェイと `config.json`」を参照してください。

---

## 3. スキル（ZeroClaw）と外部シークレットの対応（要約）

エージェントが参照する **スキル名 → MCP サーバ ID** の正は **`zeroclaw/config.toml` の `[[skills]]`** です（全 40 件）。代表的なものと、主に必要になる変数の目安を示します。

| MCP サーバ ID（`config.toml`） | 主な環境変数・備考 |
|-------------------------------|-------------------|
| `context7` | `CONTEXT7_API_KEY` |
| `sequential-thinking` | 通常はキー不要 |
| `time` | **現状 `mcp/config.json` に未定義**。ゲートウェイへサーバ追加が必要 |
| `brave-search` | `BRAVE_SEARCH_API_KEY`（サンプル `config.json` ではキー名 `search` — 名前の整合は [mcp/README.md](mcp/README.md) 参照） |
| `arxiv` / `duckduckgo` / `wikipedia` | 多くはキー不要（レート制限対策で任意 ID 等） |
| `filesystem` | パスは `mcp/config.json` の `args` で指定 |
| `git` | ローカル git 参照（workspace の bind mount 前提。外部 GitHub はオプション） |
| `github` | `GITHUB_PAT`（Compose 経由）または `GITHUB_PERSONAL_ACCESS_TOKEN`（外部版。必要時のみ） |
| `python-shell` / `curl-executor` / `openapi-spec-tool` 等 | カタログに応じた追加定義が必要な場合あり |
| `node-runtime` / `polyglot-sandbox` 等 | Docker ソケット利用。イメージ・ボリュームは `mcp/config.json` で調整 |
| `postgres` | 接続文字列は `config.json` 内（本番ではシークレット化を推奨） |
| `redis` | `REDIS_URL` 等（サーバ定義追加後） |
| `mermaid-renderer` | サンプルではキー `mermaid` — **ID の揃え方**は mcp README を参照 |
| `legal-database-api` / `trademark-patent-search` / `web-scraper` / `pdf-parser` | 契約・カタログに応じて定義 |
| `sentry` | `SENTRY_AUTH_TOKEN` 等 |
| `browserbase` | `BROWSERBASE_API_KEY` / `BROWSERBASE_PROJECT_ID` |
| `snyk` | `SNYK_TOKEN` |
| `hashicorp-vault-mcp` | `VAULT_ADDR` / `VAULT_TOKEN` |
| `aws` | `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_REGION` |
| `docker-mcp` / `kubernetes` | Docker / Kube 資格情報・`KUBECONFIG` 等 |
| `discord` / `slack` | Webhook または Bot トークン（**トークンはリポジトリに含めない**） |
| `notion` / `confluence` | `NOTION_*` / `CONFLUENCE_*` |

完全なスキル一覧と **`mcp/config.json` に既に存在するサーバ ID** の差分は [mcp/README.md](mcp/README.md) のマトリクスと整合表を参照してください。

---

## 4. 運用上の注意

- **秘密情報の取り扱い**: `.env` と `mcp/gateway.env` はコミットしないでください（`.gitignore` 済み）。
- **変数名の食い違い**: ルート `.env`（`GITHUB_PAT`）と MCP 用ファイル（`GITHUB_PERSONAL_ACCESS_TOKEN`）で名前が異なる場合があります。どちらに書いたかと、Compose が実際に渡している名前を一致させてください。
- **MCP サーバがツールとして見えない**: `zeroclaw/config.toml` の `mcp_server` と、ゲートウェイが認識する **`mcp/config.json` のキー**が一致している必要があります。Brave 検索のように **キー名が `search` と `brave-search` で異なる**場合は、どちらかに揃えるか、ゲートウェイの設定方法に合わせてください。
- **Langfuse / Open WebUI**: `docker compose --profile ui` 用の変数は `.env.example` の「12. Web UI」節を参照してください（`OPEN_WEBUI_SECRET_KEY`、`LANGFUSE_ENCRYPTION_KEY` は起動前に変更推奨）。Langfuse の `DATABASE_URL` は compose 内で `langfuse_db` に向けて補間されます。

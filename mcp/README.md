# MCP レイヤー（Docker MCP Gateway）

このディレクトリは **Model Context Protocol (MCP)** 用の設定をまとめます。ZeroClaw エージェントは `zeroclaw/config.toml` で指定したゲートウェイ URL（既定: `http://mcp-gateway:8811/sse`）経由でツールにアクセスします。

---

## 1. 正（ソース・オブ・トゥルース）の整理

| レイヤー | ファイル | 役割 |
|----------|----------|------|
| **スキル → MCP サーバ ID** | `zeroclaw/config.toml` の `[[skills]]` | 各 `name`（スキル）に `mcp_server = "..."` が対応。**エージェントがどのサーバ名を要求するか**の正はここです。現状 **40** スキルが定義されています。 |
| **ゲートウェイが起動するサーバ** | `mcp/config.json` の `mcpServers` の **キー** | Docker MCP Gateway が実際に立ち上げるプロセス定義。キー名がツール一覧に出る名前と対応します。 |
| **シークレット・接続文字列** | ルート `.env`（Compose 補間）および `mcp/gateway.env`（運用テンプレート） | 変数の意味と Compose との関係は [ENV.md](../ENV.md) を参照。 |

**整合の取り方**: `config.toml` の `mcp_server` と、`config.json` のトップレベルキーは **一致している必要**があります（サンプルでは `search` / `mermaid` に寄せています）。

---

## 2. スキルと MCP サーバ ID のマトリクス（40 スキル）

`zeroclaw/config.toml` から取得した対応です（`mcp_server` 列がゲートウェイ側で解決すべき ID）。

| カテゴリ | スキル名 (`name`) | `mcp_server` |
|----------|-------------------|--------------|
| 知能・基盤 | `knowledge_base` | `hexa_rag` |
| | `logical_reasoning` | `sequential-thinking` |
| | `time_management` | `time` |
| 調査・諜報 | `market_research` | `search` |
| | `academic_research` | `arxiv` |
| | `web_search` | `duckduckgo` |
| | `knowledge_base_lookup` | `hexa_rag` |
| 開発基盤 | `filesystem` | `filesystem` |
| | `github_api` | `github` |
| | `code_interpreter` | `python-shell` |
| | `api_testing` | `curl-executor` |
| | `api_spec_manager` | `openapi-spec-tool` |
| 多言語実行 | `runtime_js` | `node-runtime` |
| | `linter_js` | `eslint-analyzer` |
| | `runtime_backend` | `polyglot-sandbox` |
| | `linter_backend` | `backend-analyzer` |
| | `runtime_php` | `php-runtime` |
| | `linter_php` | `phpstan-analyzer` |
| | `runtime_go` | `go-runtime` |
| | `linter_go` | `golangci-analyzer` |
| | `runtime_rust` | `rust-runtime` |
| | `linter_rust` | `clippy-analyzer` |
| データ・構造 | `db_operation` | `postgres` |
| | `cache_design` | `redis` |
| | `diagram_generation` | `mermaid` |
| ドキュメント・法務 | `doc_parsing` | `pdf-parser` |
| | `legal_research` | `legal-database-api` |
| | `ip_search` | `trademark-patent-search` |
| | `platform_guideline_scraper` | `web-scraper` |
| 品質・監視 | `error_monitoring` | `sentry` |
| | `ui_inspection` | `browserbase` |
| | `vuln_scan` | `snyk` |
| | `secret_vault` | `hashicorp-vault-mcp` |
| インフラ | `cloud_compute` | `aws` |
| | `container_builder` | `docker-mcp` |
| | `container_orchestration` | `kubernetes` |
| 連携・共有 | `team_notify_discord` | `discord` |
| | `team_notify_slack` | `slack` |
| | `wiki_management` | `notion_snapshots` |
| | `enterprise_docs` | `confluence_snapshots` |

---

## 3. 現行 `mcp/config.json` に含まれるサーバキー

リポジトリに同梱されているサンプルでは、次の **17** キーのみが定義されています。上表の 40 スキルのうち、ここに無い `mcp_server` は **ゲートウェイにエントリを追加するまでツールとして利用できません**。

| `config.json` のキー | 備考 |
|----------------------|------|
| `search` | Brave Search |
| `github` | `GITHUB_PERSONAL_ACCESS_TOKEN`（ルート `.env` では `GITHUB_PAT` から Compose が注入） |
| `postgres` | envmcp 経由で DATABASE_URL から生成 |
| `filesystem` | マウントパスは `args` で指定 |
| `git` | ローカル git 参照（`mcp/git` を docker で起動。ワークスペースは Compose の bind mount） |
| `notion_snapshots` | ローカルスナップショット（`./wiki/notion`） |
| `sequential-thinking` | |
| `time` | |
| `arxiv` | |
| `duckduckgo` | |
| `hexa_rag` | ローカル RAG（Markdown -> pgvector） |
| `node-runtime` | ホストの `docker.sock` をゲートウェイから利用 |
| `polyglot-sandbox` | カスタムイメージ `imperial-polyglot-runner:latest` |
| `sentry` | |
| `context7` | `CONTEXT7_API_KEY` |
| `confluence_snapshots` | ローカルスナップショット（`./wiki/confluence`） |
| `mermaid` | |

未登録の例: `wikipedia`, `python-shell`, `redis`, `aws`, `kubernetes` など。必要なサーバは [Docker MCP カタログ](https://desktop.docker.com/mcp/catalog/v2/catalog.yaml) や各パッケージの README を参照し、`config.json` に追記してください。

---

## 4. 起動とファイル配置

- **ゲートウェイ**: `docker compose up -d` でコアスタックに含まれます（サービス名 `mcp-gateway`、ポート **8811**）。
- **マウント**: `./mcp/config.json` をコンテナに読み取り専用で渡します。`/var/run/docker.sock` を渡すため、ホストの Docker と同等の権限になります。
- **シークレット**: [ENV.md](../ENV.md) に従いルート `.env` を整備してください。`mcp/gateway.env` はテンプレート兼チェックリストです（**既定の Compose では `env_file` として読み込んでいない**点に注意）。

---

## 5. 多言語ランタイムとサンドボックス

`node-runtime` や `polyglot-sandbox` はコンテナ内でコマンドを実行します。イメージ名・ボリューム・ネットワーク制限は組織のセキュリティポリシーに合わせて `config.json` を調整してください。PHP / Go / Rust 専用の `mcp_server`（`php-runtime`, `go-runtime` 等）は、現行サンプルには含まれていないため、別途定義が必要です。

---

## 6. セキュリティ上の注意

1. **Vault**: 本番の認証情報はプロンプトに直書きせず、Vault 等の秘密管理と MCP の組み合わせを検討してください。
2. **docker.sock**: ゲートウェイからホスト Docker を操作できる設定は強い権限です。信頼できるネットワーク・最小権限の原則を適用してください。
3. **通知系トークン**: Discord / Slack の Bot トークンや Webhook は漏洩リスクが高いため、環境ごとにローテーションし、リポジトリに含めないでください。

---

## 7. メンテナンス

新しい MCP サーバを追加する場合は、(1) `mcp/config.json` にエントリを追加し、(2) 必要な環境変数を [ENV.md](../ENV.md) と `gateway.env.example` に反映し、(3) スキルとして公開するなら `zeroclaw/config.toml` の `[[skills]]` を更新してください。

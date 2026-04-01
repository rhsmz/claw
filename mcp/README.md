# ZeroClaw Enterprise: MCP Layer - The Imperial Arsenal

このディレクトリは、**「円卓の64人（The Sovereign 64）」**が現実世界を操作し、知性を実行力へと変換するための **MCP (Model Context Protocol)** サーバー群を管理します。

39のスキル（神器）が、どのサーバーによって提供され、どのエージェントに紐付けられているかを定義します。

---

## 1. 接続アーキテクチャ

エージェント（LLM）は `mcp-gateway` を通じて以下のサーバー群にアクセスします。
各サーバーは、特定のプログラミング言語ランタイム、クラウドAPI、またはローカルファイルシステムへの特権アクセスを持ちます。

---

## 2. スキル・マッピング・マトリクス (39 Skills)

| カテゴリ | スキル名 | 対応MCPサーバー | 主な利用者 |
| :--- | :--- | :--- | :--- |
| **知能・基盤** | `knowledge_base` | `context7` | 全指揮官, 監査部 |
| | `logical_reasoning` | `sequential-thinking` | 全エージェント |
| | `time_management` | `time` | PM, PMO, RM |
| **調査・諜報** | `market_research` | `brave-search` | PdM, Scout, Strategist |
| | `academic_research` | `arxiv` | CTO, Scout, Wizards |
| | `web_search` | `duckduckgo` | Support, Scout |
| | `knowledge_base_lookup` | `wikipedia` | Support, Scout |
| **開発基盤** | `filesystem` | `filesystem` | Lead, Dev, Writer |
| | `github_api` | `github` | 全エンジニア, PM |
| | `code_interpreter` | `python-shell` | Test Devs, SRE |
| | `api_testing` | `curl-executor` | Backend, Integration |
| | `api_spec_manager` | `openapi-spec-tool` | Design Pod, Consistency |
| **多言語実行** | `runtime_js` | `node-runtime` | Client Pod |
| | `linter_js` | `eslint-analyzer` | Client Reviewer |
| | `runtime_php` | `php-runtime` | Backend (PHP) |
| | `linter_php` | `phpstan-analyzer` | PHP Hardener |
| | `runtime_go` | `go-runtime` | Backend (Go), Infra |
| | `linter_go` | `golangci-analyzer` | Go Sentinel |
| | `runtime_rust` | `rust-runtime` | Backend (Rust) |
| | `linter_rust` | `clippy-analyzer` | Rust Governor |
| **データ・構造** | `db_operation` | `postgres` | Architect, Backend |
| | `cache_design` | `redis` | Middleware Tuner |
| | `diagram_generation` | `mermaid-renderer` | Architect, Writer |
| **法務・規約** | `legal_research` | `legal-db-api` | General Counsel |
| | `ip_search` | `trademark-search` | IP Specialist |
| | `doc_parsing` | `pdf-parser` | Legal Pod, GRC |
| | `platform_guideline_scraper` | `web-scraper` | Policy Liaison |
| **品質・監視** | `error_monitoring` | `sentry` | SRE, Resilience Test |
| | `ui_inspection` | `browserbase` | UX Researcher, HI Auditor |
| | `vuln_scan` | `snyk` | Security Auditor |
| | `secret_vault` | `hashicorp-vault` | Security Design |
| **インフラ** | `cloud_compute` | `aws` | Infra Pod, SRE |
| | `container_builder` | `docker-mcp` | Infra Lead, DevOps |
| | `container_orchestration` | `kubernetes` | SRE, Chaos Tester |
| **連携・共有** | `team_notify_discord` | `discord` | PM, Release Manager |
| | `team_notify_slack` | `slack` | PMO, PM |
| | `wiki_management` | `notion` | Scout, Writer |
| | `enterprise_docs` | `confluence` | Writer, CS |

---

## 3. セットアップガイド

### 3.1 サーバーの起動
`mcp-gateway` は Docker Compose 経由で起動します。
```bash
docker-compose up -d mcp-gateway
```

### 3.2 認証情報の同期
`gateway.env` に必要な API キーがすべて設定されていることを確認してください。
特に `CONTEXT7_API_KEY` と `GITHUB_PERSONAL_ACCESS_TOKEN` がないと、帝国の知能と実行力の 80% が失われます。

---

## 4. 多言語ランタイムの運用 (Polyglot Runtimes)

帝国は JS, PHP, Go, Rust を等しく愛します。各ランタイムは隔離されたサンドボックス環境（Docker）で実行されます。

- **JS/TS**: `node-runtime` を使用。`package.json` の解析から `npx` による実行まで対応。
- **PHP**: `php-runtime` を使用。`composer` 連携による依存解決と `phpstan` による静的解析を強制。
- **Go**: `go-runtime` を使用。並行処理のデッドロック検知を含むテスト実行をサポート。
- **Rust**: `rust-runtime` を使用。`cargo` ツールチェーンを用い、メモリ安全性をコンパイルレベルで検証。

---

## 5. セキュリティ・ポリシー

1.  **Vault Integration**: 本番環境の認証情報は `secret_vault` (HashiCorp Vault) を経由します。エージェントがプロンプト上に生パスワードを出力することは禁止されています。
2.  **Safety Sandbox**: すべての `code_interpreter` および `runtime` はネットワーク制限されたコンテナ内で実行されます。
3.  **Audit Logs**: すべての MCP ツール呼び出しは `storage/postgres` に監査ログとして記録され、`security_auditor` によって常時監視されます。

---

## 6. 技術調査部 (INTEL Pod) による更新

`tech_trend_scout` および `security_intel_analyst` は、週に一度この MCP レイヤーのツール自体をアップデートする責任を負います。
新しい MCP サーバーがコミュニティで公開された場合、彼らはまず `legal_risk_simulator` の承認を得た上で、この `README.md` に追記します。
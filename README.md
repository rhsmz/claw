# adbx-claw

ローカル環境向けの生成 AI スタックを **Docker Compose** でまとめたリポジトリです。Ollama による推論、LiteLLM による API 正規化とルーティング、Open WebUI によるチャット UI、ZeroClaw による軽量エージェントランタイム、Langfuse による可観測性、PostgreSQL（pgvector）による永続化とベクトル検索、Docker MCP Gateway によるツール接続の土台を、同一ネットワーク上で連携させます。

## ドキュメント一覧

| ドキュメント | 内容 |
|--------------|------|
| 本 README | 構成・クイックスタート・トラブルシューティング |
| [ENV.md](ENV.md) | `.env` / `mcp/gateway.env` の変数一覧と運用 |
| [mcp/README.md](mcp/README.md) | MCP Gateway・40 スキルと `config.json` の対応・カタログ拡張 |
| [Taskfile.yml](Taskfile.yml) | `task` コマンド（`task --list-all` で説明表示） |

## 構成概要

```mermaid
flowchart LR
  subgraph clients [クライアント]
    WebUI[Open WebUI]
    ZC[ZeroClaw]
  end
  subgraph proxy [プロキシ]
    L[LiteLLM :4000]
  end
  subgraph inference [推論]
    O[Ollama :11434]
  end
  subgraph data [データ]
    PG[(PostgreSQL + pgvector)]
  end
  subgraph ops [運用]
    LF[Langfuse :3000]
  end
  WebUI --> L
  ZC --> L
  L --> O
  L -.-> LF
  WebUI --> PG
  ZC --> PG
  LF --> PG
````

| コンポーネント | 役割 | ホスト向けポート（既定） |
|----------------|------|---------------------------|
| [PostgreSQL + pgvector](https://github.com/pgvector/pgvector) | アプリ DB・ベクトル拡張 | 5432 |
| [Ollama](https://ollama.com/) | ローカル LLM 推論 | 11434 |
| [LiteLLM](https://docs.litellm.ai/) | OpenAI 互換ゲートウェイ・モデルルーティング・Langfuse 連携 | 4000 |
| [Langfuse](https://langfuse.com/)（v2 イメージ） | トレース・分析 | 3000 |
| [ZeroClaw](https://github.com/zeroclaw-labs/zeroclaw) | Rust 製エージェントランタイム | `.env` の `ZEROCLAW_GATEWAY_PORT`（例: 42617） |
| [Docker MCP Gateway](https://github.com/docker/mcp-gateway) | MCP サーバのオーケストレーション | 8811 |
| [Open WebUI](https://openwebui.com/) | チャット UI・RAG 等 | 8080 |

### Docker Compose（本リポジトリの現状）

- **Compose ファイル**は V2 形式です（トップレベル `version` は未使用）。プロジェクト名は **`name: zeroclaw-enterprise`** で固定しています。CLI は **`docker compose`**（ハイフン無し）を想定しています（`task` からも同様）。
- **既定の `docker compose up -d`**（または `task up`）では **PostgreSQL・Redis・Ollama・LiteLLM・MCP Gateway** を起動します。各サービスに **`restart: unless-stopped`** と **ヘルスチェック**があり、LiteLLM は Postgres / Redis / Ollama が **healthy** になるまで待ってから起動します。`litellm_config.yaml` はルートをマウントし、`.env` の `DEFAULT_MODEL`（例: `gemma3:12b`）向けに `model_list` へエイリアスを用意しています。
- **ZeroClaw** は **`ghcr.io/zeroclaw-labs/zeroclaw:latest`** を **プロファイル `zeroclaw`** で任意起動します。公式デプロイに合わせ **`zeroclaw_data` ボリューム**（`/zeroclaw-data`）にワークスペースを保持し、**`zeroclaw/config.toml` を `.../.zeroclaw/config.toml` に read-only マウント**します。`[[crews]]` を含む本リポジトリの設定は OSS 版と完全には一致しない可能性があるため、起動しない場合は `zeroclaw doctor` / ログで照合してください。起動例: `docker compose --profile zeroclaw up -d` または `task up-with-zeroclaw`。
- 初回は Ollama 側でモデルを取得してください（例: `task ollama-pull`）。
- **Task** は [dotenv](https://taskfile.dev/docs/guide/#dotenv-files) でルートの `.env` を読み込みます（`sync` / `audit` / `command` 等で変数が使えます）。`desc` に `[Rust]` のような角括弧がある場合は YAML 上クォートが必要なため、Taskfile では文字列としてエスケープ済みです。

## 前提条件

  - [Docker](https://docs.docker.com/get-docker/) および [Docker Compose V2](https://docs.docker.com/compose/)（`docker compose` サブコマンドが使えること）
  - （任意）[Task](https://taskfile.dev/installation/)（`Taskfile.yml` のタスクを使う場合）
  - **GPU 利用時**: NVIDIA GPU と [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)。現行の `docker-compose.yml` の **Ollama は CPU 既定**です。GPU を使う場合は [Compose の deploy.resources](https://docs.docker.com/compose/compose-file/deploy/) で `ollama` にデバイス予約を追加してください。

## クイックスタート

### 1\. 環境変数

`.env.example` を `.env` にコピーし、パスワード・各種シークレットを変更します。

```bash
cp .env.example .env
# エディタで .env を編集
```

Windows（cmd）の例: `copy .env.example .env`

または [Task](https://taskfile.dev/) を使う場合:

```bash
task setup
```

**MCP Gateway** 用に、`mcp/gateway.env` がまだ無い場合は `mcp/gateway.env.example` をコピーして作成します（`task setup` に含まれる）。手動の例: `cp mcp/gateway.env.example mcp/gateway.env`。ゲートウェイが起動する MCP サーバの一覧は **`mcp/config.json`** で定義します。コンテナへ渡すシークレットの一部はルート `.env` から `docker-compose.yml` の `mcp-gateway.environment` で補間されます（`mcp/gateway.env` は既定では `env_file` として読み込まれません）。変数の対応表は [ENV.md](ENV.md)、スキルとの整合は [mcp/README.md](mcp/README.md) を参照してください。

### 2\. PostgreSQL 初期化スクリプトの自動実行

公式 PostgreSQL イメージは、`docker-entrypoint-initdb.d` に配置された `.sql` を**初回起動時に自動実行**します。
本リポジトリでは `docker-compose.yml` が `postgres-init/` をマウントするため、実行権限付与や手動実行は不要です（`docker compose up -d` / `task up` で反映）。

**補足**: エントリポイントは init より先に `POSTGRES_DB`（`.env` の `ZEROCLAW_DB_NAME` と一致させる）を作成し、`.sql` はその DB に接続した状態で実行を開始します。`postgres-init/01-init-databases.sql` はメイン DB に `vector` を入れたうえで、`openwebui_db` / `langfuse_db` のみ冪等に作成します。過去の失敗した init でデータディレクトリが中途半端な場合は `task down-volumes` 等でボリュームを消してから再度 `up` してください。

### 3\. 設定の検証と起動

```bash
task config
task up
```

Task を使わない場合:

```bash
docker compose config --quiet
docker compose up -d
```

### 4\. モデルの取得

Ollama コンテナが起動したら、**`.env` の `DEFAULT_MODEL` と `litellm_config.yaml` の `model_name` に存在するモデル**を pull します（例は `llama3.1`。`gemma3:12b` など別名を使う場合は両方のファイルを揃えたうえで `task ollama-pull -- MODEL=gemma3:12b` など）。

```bash
task ollama-pull
# 別モデルの例
task ollama-pull -- MODEL=gemma3:12b
```

手動の例:

```bash
docker compose exec ollama ollama pull llama3.1
```

### 5\. ブラウザで開く（例）

| 用途 | URL |
|------|-----|
| Open WebUI | http://localhost:8080 |
| Langfuse | http://localhost:3000 |
| LiteLLM（OpenAI 互換ベース） | http://localhost:4000 |
| Ollama API | http://localhost:11434 |

ZeroClaw のポートは `.env` の `ZEROCLAW_GATEWAY_PORT` に従います。

### 6\. 初回のみ（UI）

  - **Open WebUI**（http://localhost:8080）: 初回アクセスで管理者アカウントの作成を求められることがあります。
  - **Langfuse**（http://localhost:3000）: 初回にユーザー登録後、プロジェクトの **Public key / Secret key** を取得し、`.env` の `LANGFUSE_PUBLIC_KEY` / `LANGFUSE_SECRET_KEY` と一致させると、LiteLLM からのトレース取り込みが確実になります（開発用の仮値のままで動く場合もありますが、公式の自己ホスト手順に従うことを推奨します）。

## Task タスク一覧

詳細な説明は `task` または `task --list-all` で確認できます。

| タスク | 概要 |
|--------|------|
| `task` | タスク一覧表示 |
| `task setup` | 初回準備（`.env` / `gateway.env` の雛形・必要ディレクトリ作成） |
| `task up` / `down` / `ps` / `logs` | Compose の基本操作 |
| `task config` | `docker compose config` による検証 |
| `task pull` | イメージの更新取得 |
| `task down-volumes` | ボリュームごと削除（**データ全消去**・確認プロンプトあり） |
| `task ollama-pull` | Ollama 内で `pull` |

## 設定ファイル

| ファイル | 説明 |
|----------|------|
| `.env` | 秘密情報・接続情報（リポジトリに含めない。`.gitignore` 済み） |
| [ENV.md](ENV.md) | 環境変数の意味・設定手順（`.env` / `mcp/gateway.env`） |
| `mcp/gateway.env` | MCP ツール用シークレット（`.gitignore` 済み。`gateway.env.example` から作成） |
| `mcp/README.md` | MCP Gateway の設定方針（カタログ・`docker.sock`・クライアント接続） |
| `docker-compose.yml` | サービス定義・ネットワーク・ボリューム |
| `litellm_config.yaml` | LiteLLM のモデル一覧と Langfuse コールバック |
| `postgres-init/01-init-databases.sql` | 初回のみ: 複数 DB 作成と `vector` 拡張 |
| `postgres-init/02-imperial-management.sql` | 初回のみ: 管理 CLI 用 `documents` / `audit_logs`（任意で CLI の `ensure_schema` と二重でも可） |

LiteLLM 経由で呼ぶモデル名は、`litellm_config.yaml` の `model_list[].model_name` と `.env` の `DEFAULT_MODEL`（ZeroClaw 用）を一致させてください。

## Ollama と 外部 API・MCP ツールの連携

推論だけでなく、**MCP（Model Context Protocol）** と **クラウド API** で調査・開発・インフラ・法務・通知まで幅広く繋げられます。エージェント側の「どのスキルがどの MCP サーバ名を指すか」の正は **`zeroclaw/config.toml` の `[[skills]]`（現状 40 件）** です。ゲートウェイが実際に起動するプロセスは **`mcp/config.json` の `mcpServers` キー**で定義します。両者の名前は一致させる必要があり、サンプルの `config.json` には **10 キー分**しか無いため、本番で使うスキルに応じて [Docker MCP カタログ](https://desktop.docker.com/mcp/catalog/v2/catalog.yaml) 等を参照しエントリを増やしてください。詳細な対応表とギャップ一覧は **[mcp/README.md](mcp/README.md)**、環境変数は **[ENV.md](ENV.md)** を参照してください。

### 推論・ゲートウェイ（HTTP API）

| 種別 | 役割 | 設定の場所 |
|------|------|------------|
| **Ollama** | ローカル推論 | `litellm_config.yaml` の `ollama/...` と `api_base: http://ollama:11434` |
| **OpenAI / Anthropic / Google / Mistral 等** | クラウド推論（任意） | ルート `.env` の `OPENAI_API_KEY` / `ANTHROPIC_API_KEY` / `GOOGLE_API_KEY` / `MISTRAL_API_KEY` 等。`docker-compose.yml` の `litellm` 経由。 |

Open WebUI は LiteLLM（ポート 4000）を OpenAI 互換エンドポイントにしているため、UI のモデル選択でローカルとクラウドを切り替えられます。**本スタックでは推論は LiteLLM を軸に**揃えています。

### MCP 連携のカテゴリ（スキル設計上の区分）

以下は `config.toml` 上のスキル分類に対応する **代表的な連携先**です。個々のパッケージ名・起動方法は [mcp/README.md](mcp/README.md) のマトリクスと `mcp/config.json` を参照してください。

| 区分 | 主な MCP サーバ ID（例） | 想定される外部サービス・リソース |
|------|---------------------------|----------------------------------|
| **知能・基盤** | `hexa_rag`, `context7`, `sequential-thinking`, `time` | ローカル RAG、ドキュメント補助、推論補助、時刻 |
| **調査・諜報** | `search`, `arxiv`, `duckduckgo`, `wikipedia` | Brave（キー `search`）、学術検索、一般 Web・百科 |
| **開発基盤** | `filesystem`, `github`, `python-shell`, `curl-executor`, `openapi-spec-tool` | ローカルファイル、GitHub、実行・HTTP テスト、OpenAPI |
| **多言語実行** | `node-runtime`, `polyglot-sandbox`, `php-runtime`, `go-runtime`, `rust-runtime` および各 linter | コンテナ／サンドボックス上の JS・PHP・Go・Rust（`docker.sock` 利用に注意） |
| **データ・構造** | `postgres`, `redis`, `mermaid` | DB・キャッシュ・図表（`zeroclaw/config.toml` は `mermaid` に揃えています） |
| **ドキュメント・法務** | `pdf-parser`, `legal-database-api`, `trademark-patent-search`, `web-scraper` | PDF、法務 DB、商標・特許、ガイドライン取得（契約・実装は別途） |
| **品質・監視** | `sentry`, `browserbase`, `snyk`, `hashicorp-vault-mcp` | エラー監視、ブラウザ自動化、脆弱性、Vault |
| **インフラ** | `aws`, `docker-mcp`, `kubernetes` | AWS、Docker、Kubernetes（資格情報は [ENV.md](ENV.md)） |
| **連携・共有** | `discord`, `slack`, `notion_snapshots`, `confluence_snapshots` | 通知・Wiki・Confluence（Notion/Confluence はローカルスナップショットでオフライン運用） |

### シークレットと Compose

- **MCP 用**: `mcp/config.json` にサーバを足したうえで、ルート `.env`（`docker-compose.yml` の `mcp-gateway.environment` で補間される項目）や **`mcp/gateway.env.example` を元にした `mcp/gateway.env`** でキーを管理します。GitHub は `.env` の **`GITHUB_PAT`** がゲートウェイ内で `GITHUB_PERSONAL_ACCESS_TOKEN` として渡ります。
- **Brave / Context7 / Sentry / Browserbase / Snyk / Vault / AWS / 通知・Notion / Confluence** 等の変数名の対応は **[ENV.md](ENV.md)** の表を参照してください。

## 注意事項・トラブルシューティング

  - **Task が `.env` を読めない** `task` は dotenv 形式で `.env` を読み込みます。`.env` に `COMPOSER_AUTH='...'${GITHUB_PAT}'...'` のような **シェル変数展開**が入っているとパースに失敗します。`.env.example` の `COMPOSER_AUTH` の書き方に合わせ、JSON 内にトークンを直接書くか、当該行をコメントアウトしてください。

  - **MCP Gateway の pull が拒否される** イメージは **`docker/mcp-gateway`**（例: `v2` タグ）です。`mcp/gateway` は Docker Hub に無く `pull access denied` になります。`docker-compose.yml` の `mcp-gateway.image` を確認してください。

  - **MCP Gateway** 既定の Compose では `mcp/gateway.env` の有無は起動成否に直結しません（`env_file` 未使用）。`task setup` で作成しておくと変数チェックに便利です。`docker.sock` をマウントするためホスト Docker 相当の権限になります。設定の詳細は [mcp/README.md](mcp/README.md) と [Docker MCP Gateway](https://github.com/docker/mcp-gateway) を参照してください。

  - **MCP のサーバ名が合わない** `zeroclaw/config.toml` の各スキルの `mcp_server` と、`mcp/config.json` のキー名が一致している必要があります（例: 調査系は `search`）。起動失敗やツールが出ない場合は [Docker MCP カタログ](https://desktop.docker.com/mcp/catalog/v2/catalog.yaml) または `docker mcp` CLI で実名を確認し、`config.json` を修正してください。

  - **ポートが既に使われている** 5432 / 3000 / 4000 / 8080 / 8811 / 11434 / ZeroClaw 用ポートがホストで占有されているとバインドに失敗します。**PostgreSQL** は `.env` の **`POSTGRES_HOST_PORT`**（既定 `5432`）でホスト側ポートを変えられます（例: `5433`。コンテナ同士の接続は引き続き `postgres:5432`）。その他は競合プロセスを止めるか、`docker-compose.yml` の `ports` を変更します。

  - **推論が 404 / model not found** `DEFAULT_MODEL`・`litellm_config.yaml` の `model_name`・Ollama 内の `ollama list` の三者が一致しているか確認してください。

  - **ZeroClaw イメージ** 配布イメージに関する報告が [Issue \#3687](https://github.com/zeroclaw-labs/zeroclaw/issues/3687) などにあります。起動しない場合はタグの固定やビルド元の確認を検討してください。

  - **データの完全削除** `task down-volumes`（`docker compose down -v`）は PostgreSQL・Ollama・WebUI などの名前付きボリュームを削除します。復元できないので、実行前に内容を確認してください。

  - **Langfuse** 自己ホスト v2 向けの変数（`DATABASE_URL`、`NEXTAUTH_SECRET`、`SALT`、`ENCRYPTION_KEY` 等）を `.env` で必ず設定してください。公開 URL が変わる場合は `LANGFUSE_NEXTAUTH_URL` も合わせて変更します。LiteLLM からトレースが表示されないときは、Langfuse 側のプロジェクトキーと `.env` の `LANGFUSE_PUBLIC_KEY` / `LANGFUSE_SECRET_KEY` を照合してください。

## ライセンス

各 Docker イメージおよびソフトウェアは、それぞれのライセンスに従います。本リポジトリの Compose 定義のみを変更・配布する場合は、プロジェクトの方針に合わせてライセンスファイルを追加してください。
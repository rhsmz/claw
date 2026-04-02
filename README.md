# claw

ローカル環境向けの生成 AI スタックを **Docker Compose** でまとめたリポジトリです。Ollama による推論、LiteLLM による API 正規化とルーティング、Open WebUI によるチャット UI、ZeroClaw による軽量エージェントランタイム、Langfuse による可観測性、PostgreSQL（pgvector）による永続化とベクトル検索、Docker MCP Gateway によるツール接続の土台を、同一ネットワーク上で連携させます。

## ドキュメント一覧

| ドキュメント | 内容 |
|--------------|------|
| 本 README | 構成・クイックスタート・トラブルシューティング |
| [ENV.md](ENV.md) | `.env` / `mcp/gateway.env` の変数一覧と運用 |
| [mcp/README.md](mcp/README.md) | MCP Gateway・`docker.sock`・Context7 |
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

## 前提条件

  - [Docker](https://docs.docker.com/get-docker/) および [Docker Compose V2](https://docs.docker.com/compose/)（`docker compose` サブコマンドが使えること）
  - （任意）[Task](https://taskfile.dev/installation/)（`Taskfile.yml` のタスクを使う場合）
  - **GPU 利用時**: NVIDIA GPU と [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)（`docker-compose.yml` の `ollama` サービスに `deploy.resources.reservations.devices` が含まれています）

CPU のみの環境では、`docker-compose.yml` 内の `ollama` サービスから **`deploy` ブロック全体を削除**してください。Compose が GPU 予約で失敗するのを防げます。

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
task init-env
```

**MCP Gateway** 用に、`mcp/gateway.env` がまだ無い場合は `mcp/gateway.env.example` をコピーして作成します（`task init-env` に含まれる）。手動の例: `cp mcp/gateway.env.example mcp/gateway.env`。ツール用の API キーは `mcp/gateway.env` に記載し、サーバ一覧はルート `.env` の `MCP_GATEWAY_SERVERS` で調整します。詳細は [mcp/README.md](https://www.google.com/search?q=mcp/README.md) を参照してください。

### 2\. PostgreSQL 初期化スクリプトの実行権限（Linux / macOS）

公式 PostgreSQL イメージは、**実行可能な** `.sh` のみをサブプロセスで実行します。初回起動前に:

```bash
chmod +x postgres-init/01-init-databases.sh
```

Task 利用時:

```bash
task postgres-init-perm
```

上記をまとめて実行する場合:

```bash
task setup
```

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
| `task setup` | 初回準備（`init-env` + Unix では `chmod`） |
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
| `postgres-init/01-init-databases.sh` | 初回のみ: 複数 DB 作成と `vector` 拡張 |

LiteLLM 経由で呼ぶモデル名は、`litellm_config.yaml` の `model_list[].model_name` と `.env` の `DEFAULT_MODEL`（ZeroClaw 用）を一致させてください。

## Ollama と 外部API・MCPツールの連携

本スタックでは、推論モデルの選択だけでなく、MCP（Model Context Protocol）を通じて様々な外部ツールやローカルファイルと連携できます。

| 種別 | 役割 | 設定の場所 |
|------|------|------------|
| **Ollama** | ローカル推論 | `litellm_config.yaml` の `ollama/...` と `api_base: http://ollama:11434` |
| **OpenAI / Anthropic / Gemini** | クラウド推論（任意） | ルート `.env` の `OPENAI_API_KEY` 等。`docker-compose.yml` の `litellm` 経由で呼び出します。 |
| **Context7 / Web検索** | ドキュメントや最新情報の取得 | `MCP_GATEWAY_SERVERS` で `context7`, `duckduckgo` 等を指定。必要に応じ `mcp/gateway.env` にAPIキーを記載。 |
| **ファイルシステム / DB** | ローカルコードの編集、SQL実行 | Compose のボリュームマウントや環境変数（`PG_DATABASE_URL`等）を使用。 |
| **GitHub / Sentry** | Issue管理やエラーログの解析 | `mcp/gateway.env` に `GITHUB_TOKEN` や `SENTRY_AUTH_TOKEN` を記載。 |
| **Discord / Google Chat** | チャットへの通知・双方向対話 | `mcp/gateway.env` に Webhook URL または Bot トークンを記載（※Botトークン利用時は情報漏洩リスクに注意。詳細は `ENV.md` 参照）。 |

Open WebUI では LiteLLM（ポート 4000）を OpenAI 互換エンドポイントにしているため、UI のモデル選択でローカルとクラウドを切り替えられます。Ollama にだけ直接 HTTP で繋ぐのではなく、**本スタックでは LiteLLM を経由する形**で外部モデルと揃えています。

## 注意事項・トラブルシューティング

  - **MCP Gateway** `mcp/gateway.env` が無いと bind mount で `docker compose up` が失敗します。`task init-env` または `cp mcp/gateway.env.example mcp/gateway.env` で作成してください。`docker.sock` をマウントするためホスト Docker 相当の権限になります。`command` の調整・上級設定は [mcp/README.md](https://www.google.com/search?q=mcp/README.md) と [docker/mcp-gateway](https://github.com/docker/mcp-gateway) を参照してください。

  - **MCP のサーバ名が合わない** `MCP_GATEWAY_SERVERS` の名前はカタログの定義と一致している必要があります。起動失敗やツールが出ない場合は [Docker MCP カタログ](http://desktop.docker.com/mcp/catalog/v2/catalog.yaml) または `docker mcp` CLI で実名を確認し、`.env` を修正してください。

  - **ポートが既に使われている** 5432 / 3000 / 4000 / 8080 / 8811 / 11434 / ZeroClaw 用ポートがホストで占有されているとバインドに失敗します。競合プロセスを止めるか、`docker-compose.yml` の `ports` を変更します（変更後は README の URL も読み替え）。

  - **推論が 404 / model not found** `DEFAULT_MODEL`・`litellm_config.yaml` の `model_name`・Ollama 内の `ollama list` の三者が一致しているか確認してください。

  - **ZeroClaw イメージ** 配布イメージに関する報告が [Issue \#3687](https://github.com/zeroclaw-labs/zeroclaw/issues/3687) などにあります。起動しない場合はタグの固定やビルド元の確認を検討してください。

  - **データの完全削除** `task down-volumes`（`docker compose down -v`）は PostgreSQL・Ollama・WebUI などの名前付きボリュームを削除します。復元できないので、実行前に内容を確認してください。

  - **Langfuse** 自己ホスト v2 向けの変数（`DATABASE_URL`、`NEXTAUTH_SECRET`、`SALT`、`ENCRYPTION_KEY` 等）を `.env` で必ず設定してください。公開 URL が変わる場合は `LANGFUSE_NEXTAUTH_URL` も合わせて変更します。LiteLLM からトレースが表示されないときは、Langfuse 側のプロジェクトキーと `.env` の `LANGFUSE_PUBLIC_KEY` / `LANGFUSE_SECRET_KEY` を照合してください。

## ライセンス

各 Docker イメージおよびソフトウェアは、それぞれのライセンスに従います。本リポジトリの Compose 定義のみを変更・配布する場合は、プロジェクトの方針に合わせてライセンスファイルを追加してください。

# 環境変数の設定ガイド

このスタックでは、機密情報と運用パラメータを **2 種類のファイル** に分けて管理します。どちらも **Git にコミットしない** こと（`.gitignore` 済み、またはテンプレのみコミット）を前提にしています。

### 初回チェックリスト

1. [`.env.example`](.env.example) → `.env` を作成し、パスワード・Langfuse 関連・`LITELLM_MASTER_KEY` 等を本番相当に変更する。
2. [`mcp/gateway.env.example`](mcp/gateway.env.example) → `mcp/gateway.env` を作成する（`task init-env` でも一括可）。
3. `.env` の `DEFAULT_MODEL` を [`litellm_config.yaml`](litellm_config.yaml) の `model_list[].model_name` のいずれかと一致させる。
4. `LANGFUSE_ENCRYPTION_KEY` をプレースホルダの `0000...` から必ず差し替える（下記「生成例」）。
5. 初回起動後、Langfuse UI でプロジェクトの API キーを確認し、必要なら `.env` の `LANGFUSE_PUBLIC_KEY` / `LANGFUSE_SECRET_KEY` と揃える。

| ファイル | 用途 | 読み込み主体 |
|----------|------|----------------|
| リポジトリ直下の **`.env`** | Compose 全体・DB・Langfuse・LiteLLM・ZeroClaw・MCP のサーバ一覧など | `docker compose`（`docker-compose.yml` の変数展開） |
| **`mcp/gateway.env`** | Docker MCP Gateway が、各 MCP サーバコンテナへ注入する API キー等 | `mcp-gateway` サービス（`--secrets=/gateway.env`） |

テンプレートは次のとおりです。

- `.env` → [`.env.example`](.env.example) をコピー
- `mcp/gateway.env` → [`mcp/gateway.env.example`](mcp/gateway.env.example) をコピー

初回は次でもまとめて作成できます。

```bash
task init-env
```

手動の例:

```bash
cp .env.example .env
cp mcp/gateway.env.example mcp/gateway.env
```

Windows（cmd）の例: `copy .env.example .env` と `copy mcp\gateway.env.example mcp\gateway.env`

---

## 1. `.env`（プロジェクト直下）

Compose が **ホスト側**で読み、各サービスの `environment` や `command` に展開されます。値に `#` やスペースを含める場合は引用符で囲むなど、[Compose の env ファイルのルール](https://docs.docker.com/compose/environment-variables/env-file/)に従ってください。

### 1.1 PostgreSQL

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `POSTGRES_USER` | はい | DB スーパーユーザ名。各サービスの接続文字列に使用。 |
| `POSTGRES_PASSWORD` | はい | 上記ユーザのパスワード。強度の高い値に変更すること。 |

### 1.2 データベース名（初期化スクリプト・接続 URL 用）

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `ZEROCLAW_DB_NAME` | はい | ZeroClaw 用 DB 名。`postgres-init` で作成。 |
| `WEBUI_DB_NAME` | はい | Open WebUI 用 DB 名。 |
| `LANGFUSE_DB_NAME` | はい | Langfuse 用 DB 名。 |

通常は `.env.example` の既定値のままで問題ありません。変更した場合は `postgres-init/01-init-databases.sh` の既定値と整合させるか、初回起動前にのみ有効であることに注意してください（既存ボリュームがあると DB 名だけ変えても新規 DB は自動では作られません）。

### 1.3 Open WebUI

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `WEBUI_SECRET_KEY` | はい | セッション等用の秘密。十分に長いランダム文字列を推奨。 |

### 1.4 Langfuse（v2 自己ホスト）

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `LANGFUSE_DB_NAME` | はい | 上記 DB 名と同じ。 |
| `LANGFUSE_NEXTAUTH_URL` | 推奨 | ブラウザがアクセスする Langfuse の URL。既定は `http://localhost:3000`。リバースプロキシ配下では実際の公開 URL に変更。 |
| `LANGFUSE_NEXTAUTH_SECRET` | はい | NextAuth 用シークレット。推測困難なランダム文字列。 |
| `LANGFUSE_ENCRYPTION_KEY` | はい | **64 文字の 16 進数（32 バイト）**。プレースホルダの `0000...` は必ず捨てる。生成例は下記。 |
| `LANGFUSE_SALT` | はい | ソルト用のランダム文字列。 |
| `LANGFUSE_PUBLIC_KEY` | はい | LiteLLM（Langfuse コールバック）がトレースを送る先の **Langfuse プロジェクト Public key**。初回起動後、Langfuse のプロジェクト設定で表示される値と一致させる（開発用の仮値で起動できる場合もあるが、トレースが届かないときはここを疑う）。 |
| `LANGFUSE_SECRET_KEY` | はい | 上に対応する **Secret key**。 |

**`LANGFUSE_ENCRYPTION_KEY` の生成例（いずれか）**

```bash
openssl rand -hex 32
```

PowerShell:

```powershell
$b = New-Object byte[] 32
[Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($b)
-join ($b | ForEach-Object { $_.ToString('x2') })
```

Python: `python -c "import secrets; print(secrets.token_hex(32))"`

### 1.5 LiteLLM・Ollama まわり

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `OLLAMA_HOST` | 任意 | ドキュメント・スクリプト用の参照例として `.env.example` に記載。Compose 内の Ollama 接続は主に `litellm_config.yaml` の `api_base` で定義。 |
| `LITELLM_MASTER_KEY` | はい | LiteLLM プロキシのマスター API キー。Open WebUI・ZeroClaw は `OPENAI_API_KEY` として同一値を渡す想定。 |
| `DEFAULT_MODEL` | はい | ZeroClaw の既定モデル。**`litellm_config.yaml` の `model_list[].model_name` と一致**させる（例: `llama3.1`、`gemma3:12b`）。 |

### 1.6 クラウド LLM（任意）

`litellm_config.yaml` で `os.environ/...` として参照されます。未使用のキーは行ごと省略するか、空のままでも Compose では `${VAR:-}` で空文字が渡り、プロキシ起動は通常可能です（該当モデルを呼ぶとエラーになります）。

| 変数名 | 説明 |
|--------|------|
| `OPENAI_API_KEY` | OpenAI 利用時。 |
| `ANTHROPIC_API_KEY` | Anthropic 利用時。 |
| `GEMINI_API_KEY` | Google Gemini 利用時（LiteLLM の設定と対応）。 |

### 1.7 ZeroClaw

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `ZEROCLAW_GATEWAY_PORT` | はい | ZeroClaw ゲートウェイのホスト公開ポート。 |

### 1.8 MCP Gateway（サーバ一覧のみ）

| 変数名 | 必須 | 説明 |
|--------|------|------|
| `MCP_GATEWAY_SERVERS` | 推奨 | Docker MCP カタログ上の**サーバ名をカンマ区切り**。例: `duckduckgo,context7`。未設定時は `docker-compose.yml` の既定で **`duckduckgo` のみ**（`.env.example` は `context7` 込みの例）。 |

各 MCP サーバが要求する **API キー**はここではなく、後述の **`mcp/gateway.env`** に書きます。

---

## 2. `mcp/gateway.env`

**何を書くファイルか**: MCP 用の **API キーだけ**（ルート `.env` には書かない）。Gateway が読み、各 MCP サーバコンテナに渡します。  
**変数名のルール**: 使うサーバのドキュメント／[カタログ](http://desktop.docker.com/mcp/catalog/v2/catalog.yaml) に書かれた名前と **完全一致**。

よく使う例:

| 変数 | いつ必要？ | 中身 |
|------|------------|------|
| `CONTEXT7_API_KEY` | `context7` を使う・上限を上げたいとき（なくても動くことが多い） | [Context7](https://context7.com/dashboard) のキー |
| `GITHUB_TOKEN` | GitHub 系 MCP を `MCP_GATEWAY_SERVERS` に入れたとき | GitHub の [PAT](https://github.com/settings/tokens) |
| `BRAVE_API_KEY` | Brave 検索 MCP を使うとき | [Brave Search API](https://brave.com/search/api/) のキー |

`duckduckgo` と `context7` だけなら、上の 3 つは**空のまま／行ごと無しで OK**。別サーバを足したら、カタログの環境変数名をそのまま `KEY=value` で追記する。詳細は [mcp/README.md](mcp/README.md)。

---

## 3. 変更を反映するとき

- **`.env` を編集した場合**  
  影響するコンテナを再起動します。例:  
  `docker compose up -d`  
  または  
  `docker compose up -d --force-recreate litellm zeroclaw open-webui langfuse`

- **`mcp/gateway.env` を編集した場合**  
  `mcp-gateway` を再起動します。例:  
  `docker compose up -d --force-recreate mcp-gateway`

---

## 4. よくある整合性チェック

| 確認内容 | 参照先 |
|----------|--------|
| ZeroClaw が使うモデル名 | `.env` の `DEFAULT_MODEL` = `litellm_config.yaml` の `model_name` |
| Open WebUI のモデル一覧 | 上記 `model_list` に無い名前は LiteLLM 経由では選べない |
| Ollama にモデルがあるか | `docker compose exec ollama ollama list` / `ollama pull <名前>` |
| Compose の文法と変数 | `docker compose config` または `task config` |
| Langfuse のトレースが LiteLLM に載るか | `.env` の `LANGFUSE_PUBLIC_KEY` / `LANGFUSE_SECRET_KEY` と Langfuse プロジェクト設定 |
| MCP ツールが出ない／Gateway 起動失敗 | `MCP_GATEWAY_SERVERS` の綴りとカタログ定義、`mcp/gateway.env` の変数名がサーバ要求と一致しているか |

---

## 5. 関連ドキュメント

- [README.md](README.md) … 全体の起動手順・トラブルシューティング
- [mcp/README.md](mcp/README.md) … MCP Gateway・Context7・`docker.sock`
- [litellm_config.yaml](litellm_config.yaml) … モデル一覧とクラウド API 環境変数の対応
- [Taskfile.yml](Taskfile.yml) … `task init-env` 等

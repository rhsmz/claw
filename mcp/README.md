# MCP Gateway まわりの設定

このディレクトリは **Docker MCP Gateway**（`docker-compose.yml` の `mcp-gateway` サービス）向けの、リポジトリ内で管理しやすい設定の置き場です。

変数の詳細（`CONTEXT7_API_KEY` / `GITHUB_TOKEN` 等）は **[ENV.md](../ENV.md) の「2. mcp/gateway.env」** を参照してください。

## 公式の考え方（3 層）

Docker MCP Gateway は主に次の要素の組み合わせで動きます。

1. **有効にする MCP サーバ**  
   既定では Docker が配布する [MCP カタログ](http://desktop.docker.com/mcp/catalog/v2/catalog.yaml) からサーバ定義を取得し、`--servers` で名前を指定して有効化します。  
   複数指定する場合は **カンマ区切り**（例: `duckduckgo,fetch`）で、ルートの `.env` にある `MCP_GATEWAY_SERVERS` から渡しています。

2. **ツール用シークレット**  
   GitHub や検索 API など、サーバが要求する API キーは **`gateway.env`**（このディレクトリ）に `KEY=value` 形式で記載します。  
   Compose では `/gateway.env` としてマウントし、`--secrets=/gateway.env` で Gateway に読み込ませています。  
   Docker Desktop のシークレットストアを併用したい場合は、[公式ドキュメントの `--secrets`](https://github.com/docker/mcp-gateway/blob/main/docs/mcp-gateway.md) の「コロン区切り」の書式を参照し、`docker-compose.yml` の `command` を調整してください。

3. **（上級者向け）config / カタログ / プロファイル**  
   - `--config` … Gateway 用の `config.yaml` をマウントして上書きする。  
   - `--catalog` … カスタムカタログ YAML のパス。  
   - `--profile` … Docker の「プロファイル」機能が有効なとき、`docker mcp profile` で作った集合を指定。  
   詳細は [mcp-gateway.md](https://github.com/docker/mcp-gateway/blob/main/docs/mcp-gateway.md) と [profiles.md](https://github.com/docker/mcp-gateway/blob/main/docs/profiles.md) を参照してください。

## 初回にやること

1. **`gateway.env` を用意する**（未作成なら）  
   ```bash
   cp mcp/gateway.env.example mcp/gateway.env
   ```  
   Windows（cmd）: `copy mcp\gateway.env.example mcp\gateway.env`  
   または `task init-env` / `task setup` 実行時に同様のコピーが走るようにしてある場合はそれに従う。

2. **`.env` でサーバ一覧を調整する**  
   `MCP_GATEWAY_SERVERS` に、カタログに存在するサーバ名をカンマ区切りで書きます。`.env.example` では `duckduckgo,context7` を例示しています。未設定時は Compose 側の既定で **`duckduckgo` のみ** です。名前はカタログの定義と完全一致させてください。

3. **`gateway.env` にキーを足す**  
   有効にしたサーバの README / カタログ定義に書かれた環境変数名と一致させます。

## なぜ `docker.sock` をマウントするのか

Gateway はツール呼び出しのたびに **別コンテナとして MCP サーバを起動**します。そのため **ホストの Docker デーモンに API で触る必要**があり、`/var/run/docker.sock` のマウントが公式 Compose 例でも必須です。  
**ホスト上の Docker をほぼフル権限で使える**のと同格のリスクがあるため、信頼できるネットワーク・マシンでのみ使う運用を推奨します。

## クライアントからの接続（SSE）

Gateway は `--transport=sse` と `--port=8811` で待ち受けています。エディタやエージェント側の「MCP の URL 指定」が必要な場合は、次を起点に公式手順を確認してください。

- [Docker Docs: MCP Gateway](https://docs.docker.com/ai/mcp-gateway/)
- [GitHub: docker/mcp-gateway](https://github.com/docker/mcp-gateway)

接続 URL のパス（例: `/sse` など）はクライアント・Gateway のバージョンで異なることがあるため、起動ログとクライアント側ドキュメントを照合してください。

## ZeroClaw などスタック内のエージェントから使う場合

コンテナからはホストの `localhost` ではなく **サービス名**で参照します。例:

- 同一 Compose ネットワーク上の別コンテナから: `http://mcp-gateway:8811`（パスはクライアント仕様に合わせる）

ZeroClaw 側の `config.toml` や環境変数で MCP のベース URL を指定できる場合は、そこに上記を設定します（バージョンごとにキー名が異なるため、利用中の ZeroClaw の設定リファレンスを確認してください）。

## Context7（ドキュメント MCP）

[Context7](https://context7.com/docs/overview) は **LLM ではなく**、ライブラリの最新ドキュメント断片を返す **MCP サーバ／HTTP API** です。Ollama 本体に「プラグインとして取り込む」仕組みはなく、**エージェントやエディタが MCP ツールとして呼ぶ**形でスタックと組み合わせます。

1. **Docker MCP カタログ**  
   サーバ名 `context7`（イメージ例: `mcp/context7`）を有効にします。本リポジトリの `.env.example` では `MCP_GATEWAY_SERVERS=duckduckgo,context7` としています。

2. **認証**  
   無料利用ではキーなしでも動く場合があります。上限を上げるには [API キー](https://context7.com/howto/api-keys) を発行し、**`mcp/gateway.env`** に次を追記します（Gateway が各 MCP コンテナへ注入します）。  
   `CONTEXT7_API_KEY=ctx7sk_...`

3. **REST API を直接叩く場合**  
   エージェントのカスタムツールから [Context7 HTTP API](https://context7.com/docs/api-guide)（`Authorization: Bearer ...`）を呼ぶこともできます。その場合は MCP Gateway とは別経路のため、キー管理とレート制限をアプリ側で行ってください。

推論は引き続き **Ollama（または LiteLLM 経由のクラウドモデル）**、根拠付けの資料取得に **Context7**、という役割分担になります。

## ローカルサーバ定義（`file://`）

カタログではなく自作・社内用のサーバ YAML を使う場合は、[Server Entry Specification](https://github.com/docker/mcp-gateway/blob/main/docs/server-entry-spec.md) に沿ったファイルをこのディレクトリに置き、ホストで `docker mcp profile create` と `--profile` を使う方法が一般的です。Compose 内コンテナだけで完結させる場合は、該当ファイルをボリュームマウントし、`command` に `--catalog` や `--servers` を追加する形で調整してください。

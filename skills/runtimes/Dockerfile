# =============================================================================
# ZeroClaw AI Empire - Polyglot Runtime Sandbox
# =============================================================================
FROM debian:bookworm-slim

# 1. システム全体の共通依存関係とビルドツールのインストール
# 開発に必須の curl, git, build-essential (gcc/make等) を含めます。
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    ca-certificates \
    build-essential \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# 2. Node.js (JavaScript / TypeScript)
# 最新のLTS版（v20）をインストール。npm, npx も同梱されます。
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# 3. PHP & Composer
# PHP-CLIと、依存管理に不可欠な Composer をインストールします。
RUN apt-get install -y \
    php-cli \
    php-xml \
    php-mbstring \
    php-zip \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# 4. Go (Golang)
# 1.22以降の安定版をマルチステージビルド風に公式イメージからコピー。
COPY --from=golang:1.22-bookworm /usr/local/go /usr/local/go
ENV PATH="/usr/local/go/bin:${PATH}"

# 5. Rust & Cargo
# rustupを使用して標準的な開発環境を構築。パスを環境変数に追加します。
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# 6. 実行ディレクトリと権限の設定
# エージェントが作業を行う領域を確保。
WORKDIR /app
VOLUME /app

# 7. エントリポイントの配備
# コンテナ起動時に各言語のコマンドを適切に処理するスクリプトをコピー。
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# バニラ状態では安全のために非特権ユーザーでの実行も検討されますが、
# 初期構築時は root 権限でパッケージ操作を行えるようにします。
ENTRYPOINT ["entrypoint.sh"]
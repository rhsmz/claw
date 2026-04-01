#!/bin/bash
set -e

# =============================================================================
# Polyglot Runtime Entrypoint
# =============================================================================

# 引数がない場合はヘルプ（バージョン確認）を表示
if [ $# -eq 0 ]; then
    echo "--- Imperial Polyglot Sandbox ---"
    node -v
    php -v
    go version
    rustc --version
    exit 0
fi

# 言語別のショートカット処理
# 例: "js main.js" や "rust run" などの直感的な命令に対応
case "$1" in
    js|node)
        shift
        exec node "$@"
        ;;
    php)
        shift
        exec php "$@"
        ;;
    go)
        shift
        exec go "$@"
        ;;
    rust|cargo)
        shift
        exec cargo "$@"
        ;;
    *)
        # それ以外のコマンド（ls, cat 等）はそのまま実行
        exec "$@"
        ;;
esac
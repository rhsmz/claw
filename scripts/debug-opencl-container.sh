#!/usr/bin/env bash
# opencl-inference コンテナ内の OpenCL 診断（WSL + Docker 前提。イメージに clinfo 必須）
set -euo pipefail
cd "$(dirname "$0")/.."
NAME="${OPENCL_CONTAINER_NAME:-}"
if [[ -z "$NAME" ]]; then
  NAME="$(docker compose ps -q opencl-inference 2>/dev/null | head -1 || true)"
fi
if [[ -z "$NAME" ]]; then
  NAME="zeroclaw-enterprise-opencl-inference-1"
fi

if ! docker inspect "$NAME" >/dev/null 2>&1; then
  echo "opencl-inference コンテナが見つかりません（docker compose --profile opencl-wsl up -d 後に再実行）" >&2
  exit 1
fi

echo "=== コンテナ ID/名: $NAME ==="
docker exec "$NAME" sh -c 'uname -a 2>/dev/null || true'
echo
echo "=== デバイス ==="
docker exec "$NAME" sh -c 'ls -la /dev/dxg /dev/dri 2>&1 || true'
echo
echo "=== WSL ライブラリ（マウント確認）==="
docker exec "$NAME" sh -c 'ls -la /usr/lib/wsl/lib 2>&1 | head -20'
echo
echo "=== OpenCL ICD ==="
docker exec "$NAME" sh -c 'ls -la /etc/OpenCL/vendors/ 2>&1; for f in /etc/OpenCL/vendors/*.icd; do echo "--- $f ---"; cat "$f" 2>/dev/null || true; done'
echo
echo "=== LD_LIBRARY_PATH（プロセス環境）==="
docker exec "$NAME" sh -c 'tr "\0" "\n" < /proc/1/environ 2>/dev/null | grep LD_ || env | grep LD_ || true'
echo
echo "=== clinfo -l（GPU が出ればマウント成功に近い）==="
docker exec "$NAME" sh -c 'if command -v clinfo >/dev/null; then clinfo -l; elif test -x /usr/bin/clinfo; then /usr/bin/clinfo -l; else echo "clinfo なし（task build-opencl-inference でイメージに追加）"; fi' 2>&1
echo
echo "=== llama ログの ggml_opencl（直近）==="
docker logs "$NAME" 2>&1 | grep -iE 'ggml_opencl|opencl|platform|gpu' | tail -15 || true

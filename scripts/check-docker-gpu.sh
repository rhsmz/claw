#!/usr/bin/env bash
# Docker 内で Intel GPU（OpenCL）が見えるかざっくり確認（WSL 想定）
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== 1) opencl-inference（profile opencl-wsl）==="
CID="$(docker compose ps -q opencl-inference 2>/dev/null | head -1 || true)"
if [[ -z "$CID" ]]; then
  echo "[--] コンテナなし（docker compose --profile opencl-wsl up -d opencl-inference）"
else
  echo "[OK] コンテナ ID: $CID"
  echo "--- llama ggml_opencl（起動時・直近）---"
  docker logs "$CID" 2>&1 | grep -iE 'ggml_opencl: (selected platform|device:|platform IDs)' | tail -8 || echo "(該当ログなし)"
  echo "--- clinfo ---"
  docker exec "$CID" sh -c 'if command -v clinfo >/dev/null; then clinfo -l; elif test -x /usr/bin/clinfo; then /usr/bin/clinfo -l; else echo "[--] clinfo 未インストール（ビルド成功後に利用可）"; fi' 2>&1 || true
fi
echo

echo "=== 2) 使い捨てコンテナで /dev/dxg と /usr/lib/wsl が見えるか（パススルー確認）==="
if [[ ! -e /dev/dxg ]]; then
  echo "[--] ホストに /dev/dxg なし（WSL 外？）スキップ"
else
  docker run --rm \
    --device /dev/dxg \
    -v /usr/lib/wsl:/usr/lib/wsl:ro \
    ubuntu:24.04 \
    bash -c 'ls -la /dev/dxg; echo ---; ls /usr/lib/wsl/lib 2>/dev/null | head -5' 2>&1 || echo "[!] docker run 失敗（pull や creds を確認）"
fi
echo

echo "=== 3) rust-inference（SYCL/GPU はログで確認）==="
RID="$(docker compose ps -q rust-inference 2>/dev/null | head -1 || true)"
if [[ -z "$RID" ]]; then
  echo "[--] rust-inference なし"
else
  docker logs "$RID" 2>&1 | grep -iE 'SYCL|sycl|level_zero|gpu|no usable GPU|backend' | tail -12 || echo "(該当ログなし)"
  if docker logs "$RID" 2>&1 | grep -qiE 'RUST_INFERENCE_DISABLE_SYCL_PLUGIN=1'; then
    echo "[情報] rust-inference は WSL 既定で SYCL を無効化（CPU）。GPU 推論は opencl-inference（profile opencl-wsl）。SYCL GPU を試す: .env で RUST_INFERENCE_DISABLE_SYCL_PLUGIN=0"
  elif docker logs "$RID" 2>&1 | grep -qiE 'cpu backend only|CPU only|no usable GPU'; then
    echo "[ヒント] WSL+Intel: docker-compose.rust-inference-gpu-wsl.yml、または GPU は opencl-inference（profile opencl-wsl）"
  fi
fi

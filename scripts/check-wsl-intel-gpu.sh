#!/usr/bin/env bash
# WSL2 + Intel GPU の確認用（ホスト WSL 内で実行: bash scripts/check-wsl-intel-gpu.sh）
set -euo pipefail

echo "=== カーネル ==="
uname -r
echo

echo "=== デバイスノード ==="
if [[ -d /dev/dri ]]; then
  echo "[OK] /dev/dri あり"
  ls -la /dev/dri
else
  echo "[--] /dev/dri なし（Docker の DRM マウント・opencl-inference の bind が失敗することがある）"
  echo "    試行: sudo modprobe vgem  →  ls -la /dev/dri   （永続: /etc/modules に vgem）"
  echo "    詳細: リポジトリの WSL2+Intel Arc+/dev/dri 実装ガイド.md"
fi
if [[ -e /dev/dxg ]]; then
  echo "[OK] /dev/dxg あり（WSL の D3D ブリッジ）"
  ls -la /dev/dxg
else
  echo "[--] /dev/dxg なし"
fi
echo

echo "=== DRM sysfs（card が無ければカーネルが GPU を DRM として出していない）==="
if [[ -d /sys/class/drm ]]; then
  ls -la /sys/class/drm | head -20
else
  echo "なし"
fi
echo

echo "=== OpenCL（clinfo があれば）==="
if command -v clinfo >/dev/null 2>&1; then
  clinfo -l 2>&1 || true
  _clinfo_full=$(clinfo 2>&1 || true)
  if echo "${_clinfo_full}" | grep -qi intel; then
    echo "[OK] clinfo の出力に Intel が含まれる（ユーザーランドから GPU が列挙できている可能性が高い）"
  else
    echo "[--] clinfo に Intel デバイスが見えない。Intel GPU リポジトリで intel-opencl-icd 等を導入: ENV.md / Intel WSL GPU 手順"
  fi
  unset _clinfo_full
else
  echo "clinfo 未インストール（sudo apt install clinfo）"
fi
echo

echo "=== SYCL / Level Zero（sycl-ls があれば）==="
if command -v sycl-ls >/dev/null 2>&1; then
  sycl-ls 2>&1 || true
else
  echo "sycl-ls なし（oneAPI 完全導入時のみ。無くても可）"
fi
echo

echo "=== Intel Level Zero ユーザーランド（dpkg）==="
if command -v dpkg >/dev/null 2>&1; then
  dpkg -l 2>/dev/null | grep -iE '^ii\s+(level-zero|intel-level-zero)' || echo "level-zero 系パッケージなし"
else
  echo "dpkg なし"
fi
echo

echo "=== .wslconfig（Windows ユーザープロファイル直下）==="
echo "Intel Community のサポート回答では [wsl2] で nestedVirtualization=true の確認・wsl --update が案内されています。"
echo "https://community.intel.com/t5/Graphics/Cannot-get-dev-dri-to-appear-in-WSL-2-for-Intel-Iris-Xe-12th-Gen/td-p/1724203"
echo "（GPU 用の公式オプションは Microsoft ドキュメントと併せて確認してください。）"
echo

echo "=== 解釈の目安 ==="
echo "- /dev/dxg だけある: WSL2 では GPU が /dev/dxg（D3D）側に出ることがある。Docker では --device /dev/dxg が案内されることもある。"
echo "- clinfo で GPU が見える: OpenCL 経由の計算はユーザーランドで可能なことがある。"
echo "- rust-inference（llama SYCL）: DRM の /dev/dri を前提としがち。/dev/dxg だけの場合は docker-compose.rust-inference-gpu-wsl.yml（実験）を参照。"
echo "- opencl-inference（--profile opencl-wsl）: compose が /dev/dri を bind。WSL で無い場合は modprobe vgem 後に再確認。"
echo "  Intel WSL GPU: https://www.intel.com/content/www/us/en/docs/oneapi/installation-guide-linux/2024-2/configure-wsl-2-for-gpu-workflows.html"
echo

echo "=== Docker への繋ぎ込み（本リポジトリ）==="
if command -v docker >/dev/null 2>&1; then
  echo "[OK] docker CLI: $(docker --version 2>/dev/null | head -1)"
else
  echo "[--] docker CLI なし（Docker Desktop の WSL 統合を有効にするか apt install docker.io）"
fi
echo
echo "[A] opencl-inference（GGML OpenCL）— Intel: WSL では dxcore 用に /usr/lib/wsl をツリーごとマウント（lib だけだと GPU 0 件になりやすい: intel/compute-runtime#625）"
echo "    1) 無ければ: task wsl-setup-gpu  または  bash scripts/wsl-setup-gpu.sh"
echo "    2) ビルド・起動: task build-opencl-inference && task up-with-opencl-wsl"
echo "    3) 診断: bash scripts/debug-opencl-container.sh"
echo "    4) ログ: docker compose logs opencl-inference 2>&1 | grep -iE 'ggml_opencl|opencl|gpu|offload'"
echo
echo "[B] rust-inference（llama SYCL / Level Zero）— マウント: /dev/dri（要 GPU 用再ビルド）"
echo "    docker compose -f docker-compose.yml -f docker-compose.rust-inference-gpu.yml build rust-inference"
echo "    docker compose -f docker-compose.yml -f docker-compose.rust-inference-gpu.yml up -d --force-recreate rust-inference"
echo "    ログ: docker compose logs rust-inference 2>&1 | grep -iE 'sycl|SYCL|gpu|offload|level_zero'"
echo
echo "[C] 疎通: bash scripts/stack-smoke-test.sh（9080 / 9081 の /health）"

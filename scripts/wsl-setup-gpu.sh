#!/usr/bin/env bash
# WSL2 で GPU 関連デバイスを用意する（Docker の前に実行）。
# - /dev/dxg … Windows WDDM ブリッジ（通常は既に存在）
# - /dev/dri … 無い環境では Virtual GEM（vgem）で DRM ノードを生成
#
# 使い方（リポジトリルート想定）:
#   bash scripts/wsl-setup-gpu.sh
#   PERSIST_VGEM=1 bash scripts/wsl-setup-gpu.sh   # 再起動後も vgem を自動ロード（/etc/modules に追記）
#
# sudo が必要です（modprobe）。

set -euo pipefail

echo "=== WSL GPU 前提セットアップ ==="

if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
  echo "[OK] WSL カーネルと判定"
else
  echo "[!] WSL 以外かもしれません。ネイティブ Linux では通常 /dev/dri は別手順です。"
fi
echo

echo "=== /dev/dxg（D3D ブリッジ）==="
if [[ -e /dev/dxg ]]; then
  echo "[OK] /dev/dxg あり"
  ls -la /dev/dxg
else
  echo "[!] /dev/dxg なし。Windows 側の GPU ドライバ・WDDM 2.9+、\`wsl --update\` を確認してください。"
fi
echo

has_dri_nodes() {
  [[ -d /dev/dri ]] || return 1
  local n
  n=$(find /dev/dri -maxdepth 1 -type c \( -name 'renderD*' -o -name 'card*' \) 2>/dev/null | wc -l)
  [[ "${n}" -gt 0 ]]
}

echo "=== /dev/dri（DRM。Docker bind や OpenCL/SYCL の前提になりうる）==="
if has_dri_nodes; then
  echo "[OK] /dev/dri に card/renderD ノードが既にあります"
  ls -la /dev/dri
else
  echo "[*] ノードが足りないため vgem をロードします（sudo modprobe vgem）…"
  if ! sudo modprobe vgem; then
    echo "[!] modprobe vgem に失敗しました。カーネルに DRM_VGEM が無い、または権限がありません。" >&2
    exit 1
  fi
  sleep 0.3
  if has_dri_nodes || [[ -d /dev/dri ]]; then
    echo "[OK] modprobe 後の /dev/dri:"
    ls -la /dev/dri 2>/dev/null || true
  else
    echo "[!] modprobe 後も /dev/dri が期待どおり出ませんでした。カーネル・WSL バージョンを確認してください。" >&2
    exit 1
  fi
fi
echo

if [[ "${PERSIST_VGEM:-}" == "1" ]]; then
  echo "=== /etc/modules へ vgem を永続化（PERSIST_VGEM=1）==="
  if [[ -f /etc/modules ]] && grep -qxF 'vgem' /etc/modules; then
    echo "[OK] 既に vgem が登録されています"
  else
    echo vgem | sudo tee -a /etc/modules >/dev/null
    echo "[OK] /etc/modules に vgem を追記しました"
  fi
  echo
fi

echo "=== 任意: ホストユーザーで render グループ（Permission denied 時）==="
echo "    sudo gpasswd -a \"\$USER\" render && newgrp render"
echo

echo "=== 確認 ==="
echo "    bash scripts/check-wsl-intel-gpu.sh"
echo "その後 Docker: task up-with-opencl-wsl 等"

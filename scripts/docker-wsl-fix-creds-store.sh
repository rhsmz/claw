#!/usr/bin/env bash
# WSL / Linux: Docker Hub の公開 pull で "error getting credentials" になるときの応急処置。
# credsStore が壊れた docker-credential-* を呼び、exit 1 になるケースが多い（WSL + Docker Desktop 連携時など）。
#
# 使い方: bash scripts/docker-wsl-fix-creds-store.sh
#  ~/.docker/config.json を .bak 付きで退避し、credsStore を削除（credHelpers の docker.io も削除）。
# プライベートレジストリ用のログインはその後 `docker login` で再設定してください。

set -euo pipefail

CFG="${DOCKER_CONFIG:-$HOME/.docker}/config.json"
DIR="$(dirname "$CFG")"
mkdir -p "$DIR"

if [[ -f "$CFG" ]]; then
  cp -a "$CFG" "${CFG}.bak.$(date +%Y%m%d%H%M%S)"
  echo "バックアップ: ${CFG}.bak.*"
fi

python3 <<'PY'
import json, os, sys

cfg_path = os.path.join(os.environ.get("DOCKER_CONFIG") or os.path.join(os.path.expanduser("~"), ".docker"), "config.json")
os.makedirs(os.path.dirname(cfg_path), exist_ok=True)
data = {}
if os.path.isfile(cfg_path):
    with open(cfg_path, encoding="utf-8") as f:
        try:
            data = json.load(f)
        except json.JSONDecodeError:
            print("警告: 既存 config.json が壊れています。最小構成で上書きします。", file=sys.stderr)
            data = {}

data.pop("credsStore", None)
ch = data.get("credHelpers")
if isinstance(ch, dict):
    ch.pop("docker.io", None)
    ch.pop("index.docker.io", None)
    if not ch:
        data.pop("credHelpers", None)
    else:
        data["credHelpers"] = ch

if "auths" not in data:
    data["auths"] = {}

with open(cfg_path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)
    f.write("\n")

print("更新:", cfg_path)
print("credsStore / docker.io の credHelpers を除去しました。")
PY

echo "続けて: docker pull ubuntu:24.04  または  task build-opencl-inference"

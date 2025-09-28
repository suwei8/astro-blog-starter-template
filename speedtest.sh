#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.12"
BASE_URL="https://github.com/librespeed/speedtest-cli/releases/download/v${VERSION}"
SERVER_URL="${SERVER_URL:-http://wky.555606.xyz:8080}"
LOG_FILE="speedtest.log"

# --- 架构选择（与你现在一致） ---
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)   PKG="librespeed-cli_${VERSION}_linux_amd64.tar.gz" ;;
  armv6*|armv7*|armhf) PKG="librespeed-cli_${VERSION}_linux_armv6.tar.gz" ;;
  aarch64|arm64)  echo "[ERROR] 当前架构 $ARCH 没有官方预编译包，请在支持架构上运行或自行编译。"; exit 1 ;;
  *)              echo "[ERROR] 未知架构: $ARCH"; exit 1 ;;
esac

echo "[INFO] arch-detect: $ARCH  ->  $(echo "$PKG" | sed 's/.*linux_\([^\.]*\).*/\1/') ($PKG)"
WORKDIR="$(mktemp -d)"; trap 'rm -rf "$WORKDIR"' EXIT

echo "[INFO] downloading $PKG ..."
wget -q -O "$WORKDIR/$PKG" "$BASE_URL/$PKG"
tar -xzf "$WORKDIR/$PKG" -C "$WORKDIR"
BIN="$WORKDIR/librespeed-cli"; chmod +x "$BIN"

# v1.0.12 的简写 servers.json（CLI 会自己拼接后端路径）
cat > "$WORKDIR/servers.json" <<EOF
[
  { "id": 1, "name": "My LibreSpeed", "server": "${SERVER_URL}" }
]
EOF

echo "[INFO] running test against ${SERVER_URL} ..."
RESULT="$("$BIN" --local-json "$WORKDIR/servers.json" --server 1 --json || true)"

# 追加原始 JSON 到日志（保持机器可读）
if [[ -n "$RESULT" ]]; then
  echo "$RESULT" >> "$LOG_FILE"
fi

# ---- 人类可读的美化输出（优先用 jq）----
if command -v jq >/dev/null 2>&1 && [[ -n "$RESULT" && "$RESULT" != "null" ]]; then
  echo "$RESULT" | jq -r '
    .[] |
    "时间: \(.timestamp)\n服务器: \(.server.name) (\(.server.url))\n" +
    "Ping: \(.ping) ms   Jitter: \(.jitter) ms\n" +
    "下行: \(.download) Mbps   上行: \(.upload) Mbps\n"'
else
  # 没有 jq 就退回原始 JSON（避免“看不到输出”的情况）
  [[ -n "$RESULT" ]] && echo "$RESULT" || echo "[ERROR] 未获得结果"
  [[ ! $(command -v jq) ]] && echo "[WARN] 未安装 jq，无法美化输出。Debian/Ubuntu: apt-get install -y jq"
fi

echo "[INFO] done. appended to $LOG_FILE"

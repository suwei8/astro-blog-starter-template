#!/usr/bin/env bash
set -euo pipefail

VERSION="1.0.12"
BASE_URL="https://github.com/librespeed/speedtest-cli/releases/download/v${VERSION}"
SERVER_URL="${SERVER_URL:-http://wky.555606.xyz:8080}"
LOG_FILE="speedtest.log"

# 自动检测架构
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64|amd64)   PKG="librespeed-cli_${VERSION}_linux_amd64.tar.gz" ;;
  armv6*|armv7*|armhf) PKG="librespeed-cli_${VERSION}_linux_armv6.tar.gz" ;;
  aarch64|arm64)
    echo "[ERROR] 当前架构 $ARCH 没有官方预编译包，请自行编译。"; exit 1 ;;
  *) echo "[ERROR] 未知架构: $ARCH"; exit 1 ;;
esac

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "[INFO] 检测到架构: $ARCH"
echo "[INFO] 下载 $PKG ..."
wget -q -O "$WORKDIR/$PKG" "$BASE_URL/$PKG"
tar -xzf "$WORKDIR/$PKG" -C "$WORKDIR"
BIN="$WORKDIR/librespeed-cli"
chmod +x "$BIN"

# servers.json
cat > "$WORKDIR/servers.json" <<EOF
[
  {
    "id": 1,
    "name": "My LibreSpeed",
    "server": "${SERVER_URL}"
  }
]
EOF

echo "[INFO] 开始测速..."
RESULT=$("$BIN" --local-json "$WORKDIR/servers.json" --server 1 --json)
echo "$RESULT" >> "$LOG_FILE"

# 输出美化结果
if command -v jq >/dev/null 2>&1; then
  echo "$RESULT" | jq -r '
    .[] | "时间: \(.timestamp)\n服务器: \(.server.name)\nPing: \(.ping) ms\nJitter: \(.jitter) ms\n下载: \(.download) Mbps\n上传: \(.upload) Mbps\n"'
else
  echo "$RESULT"
  echo "[WARN] 未安装 jq，无法美化输出，已显示原始 JSON"
fi

echo "[INFO] 结果已保存到 $LOG_FILE"

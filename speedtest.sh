#!/usr/bin/env bash
set -e

# ========================
# LibreSpeed CLI Speedtest
# ========================

# 配置
REPO_URL="https://github.com/librespeed/speedtest-cli/releases/download/v1.0.12"
TAR_NAME="librespeed-cli_1.0.12_linux_armv6.tar.gz"
BIN_NAME="librespeed-cli"
SERVER_JSON="servers.json"
LOG_FILE="speedtest.log"

# 1. 下载并解压 librespeed-cli
if [ ! -f "$BIN_NAME" ]; then
  echo "[INFO] 下载 librespeed-cli..."
  wget -q -O "$TAR_NAME" "$REPO_URL/$TAR_NAME"
  tar -xzf "$TAR_NAME"
  rm -f "$TAR_NAME"
fi

# 2. 写入 servers.json
cat > "$SERVER_JSON" <<EOF
[
  {
    "id": 1,
    "name": "My LibreSpeed",
    "server": "http://wky.555606.xyz:8080"
  }
]
EOF

# 3. 执行测速
echo "[INFO] 开始测速..."
./$BIN_NAME --local-json $SERVER_JSON --server 1 --json | tee -a "$LOG_FILE"

echo "[INFO] 测速完成，结果已追加到 $LOG_FILE"

#!/usr/bin/env bash
set -e

# ========================
# LibreSpeed CLI Speedtest
# 自动检测 CPU 架构并下载对应版本
# ========================

# 仓库地址
BASE_URL="https://github.com/librespeed/speedtest-cli/releases/download/v1.0.12"

# 自动检测架构
ARCH=$(uname -m)
case "$ARCH" in
  armv6*|armv7*|armhf)
    TAR_NAME="librespeed-cli_1.0.12_linux_armv6.tar.gz"
    ;;
  aarch64)
    # 没有单独的 aarch64 包，暂时用 amd64 包可能会失败
    TAR_NAME="librespeed-cli_1.0.12_linux_amd64.tar.gz"
    ;;
  x86_64|amd64)
    TAR_NAME="librespeed-cli_1.0.12_linux_amd64.tar.gz"
    ;;
  *)
    echo "[ERROR] 未知架构: $ARCH"
    echo "请手动指定 arm 或 amd"
    exit 1
    ;;
esac

BIN_NAME="librespeed-cli"
SERVER_JSON="servers.json"
LOG_FILE="speedtest.log"

# 1. 下载并解压 librespeed-cli
if [ ! -f "$BIN_NAME" ]; then
  echo "[INFO] 检测到架构: $ARCH"
  echo "[INFO] 下载 $TAR_NAME ..."
  wget -q -O "$TAR_NAME" "$BASE_URL/$TAR_NAME"
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

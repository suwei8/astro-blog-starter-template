#!/usr/bin/env bash
set -euo pipefail

# LibreSpeed CLI one-shot runner (v1.0.12)
# - Auto-detect CPU arch (or override with arg: amd | arm)
# - Download correct binary, run once, append JSON to speedtest.log

VERSION="1.0.12"
BASE_URL="https://github.com/librespeed/speedtest-cli/releases/download/v${VERSION}"
SERVER_URL="${SERVER_URL:-http://wky.555606.xyz:8080}"   # 可用环境变量覆盖

usage() {
  echo "Usage: $0 [amd|arm]"
  echo "No arg = auto-detect arch. You can also set SERVER_URL env."
}

# 1) 解析可选架构参数（手动覆盖）
OVERRIDE="${1:-}"
if [[ -n "$OVERRIDE" && "$OVERRIDE" != "amd" && "$OVERRIDE" != "arm" ]]; then
  usage; exit 1
fi

# 2) 自动检测架构
ARCH_DET="$(uname -m 2>/dev/null || true)"
if [[ -z "$OVERRIDE" ]]; then
  case "$ARCH_DET" in
    x86_64|amd64) PKG="librespeed-cli_${VERSION}_linux_amd64.tar.gz"; FLAVOR="amd";;
    armv6*|armv7*|armhf) PKG="librespeed-cli_${VERSION}_linux_armv6.tar.gz"; FLAVOR="arm";;
    aarch64|arm64)
      echo "[ERROR] Detected arch: $ARCH_DET. v${VERSION} 没有官方 arm64/aarch64 预编译包。"
      echo "        选项："
      echo "        1) 在 x86_64/amd64 或 armv6/armv7 机器上运行本脚本；"
      echo "        2) 自行从源码编译：  git clone https://github.com/librespeed/speedtest-cli && cd speedtest-cli && ./build.sh"
      exit 2
      ;;
    *)
      echo "[ERROR] 未知/不支持的架构: $ARCH_DET"
      echo "        仅支持自动下载 amd64 或 armv6/armv7。可手动传参：$0 amd  或  $0 arm"
      exit 2
      ;;
  esac
else
  if [[ "$OVERRIDE" == "amd" ]]; then
    PKG="librespeed-cli_${VERSION}_linux_amd64.tar.gz"; FLAVOR="amd"
  else
    PKG="librespeed-cli_${VERSION}_linux_armv6.tar.gz"; FLAVOR="arm"
  fi
fi

echo "[INFO] arch-detect: ${OVERRIDE:-$ARCH_DET}  ->  $FLAVOR ($PKG)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

# 3) 下载并解压
echo "[INFO] downloading $PKG ..."
wget -q -O "$WORKDIR/$PKG" "$BASE_URL/$PKG"
tar -xzf "$WORKDIR/$PKG" -C "$WORKDIR"

BIN="$WORKDIR/librespeed-cli"
chmod +x "$BIN"

# 4) 生成 servers.json（v1.0.12 简写格式，CLI 会自行拼接后端路径）
cat > "$WORKDIR/servers.json" <<EOF
[
  {
    "id": 1,
    "name": "My LibreSpeed",
    "server": "${SERVER_URL}"
  }
]
EOF

# 5) 执行测速
echo "[INFO] running test against ${SERVER_URL} ..."
LOG_FILE="speedtest.log"
if ! "$BIN" --local-json "$WORKDIR/servers.json" --server 1 --json | tee -a "$LOG_FILE" ; then
  echo "[ERROR] 运行失败。可能原因："
  echo "  - 服务器 ${SERVER_URL} 无法访问或后端未就绪"
  echo "  - 架构误判：当前 uname -m='$ARCH_DET'，使用包 '$PKG'"
  echo "尝试手动覆盖架构："
  echo "  bash <(curl -fsSL https://raw.githubusercontent.com/<you>/<repo>/main/speedtest.sh) amd"
  echo "或  bash <(... ) arm"
  exit 3
fi

echo "[INFO] done. appended to $LOG_FILE"

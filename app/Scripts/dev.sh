#!/bin/bash
# 开发快速迭代：构建 → 直接运行调试二进制（免装 .app / DMG）。
# 用法:
#   Scripts/dev.sh          构建并启动一次
#   Scripts/dev.sh --watch  监听 Sources/，保存后自动重建并重启
# 退出: Ctrl+C（watch 模式）；启动的 App 可右键菜单栏图标退出。
set -u
cd "$(dirname "$0")/.."

BIN="$PWD/.build/debug/FirstLight"

restart() {
  pkill -f "$BIN" 2>/dev/null || true
  sleep 0.3
  "$BIN" --window > /tmp/firstlight-dev.log 2>&1 &
  echo "▶ 已启动 (pid $!)，主窗口自动打开，日志 /tmp/firstlight-dev.log"
}

build() {
  echo "🔨 swift build …"
  if ! swift build; then
    echo "❌ 构建失败，保留正在运行的旧实例"
    return 1
  fi
}

case "${1:-run}" in
  run)
    build && restart
    ;;
  watch)
    echo "👀 监听 Sources/ 下的 Swift 改动，Ctrl+C 退出"
    while true; do
      changed=$(find Sources -name '*.swift' -newer "$BIN" -print -quit 2>/dev/null)
      if [[ -n "$changed" ]]; then
        echo "🔄 检测到改动: $changed"
        build && restart
      fi
      sleep 1
    done
    ;;
  *)
    echo "用法: Scripts/dev.sh [--watch]"
    exit 1
    ;;
esac

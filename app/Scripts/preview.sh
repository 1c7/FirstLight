#!/bin/bash
# 离屏渲染主窗口 → /tmp/fl-main.png（2x），并打印每层 view 的最终 frame。
# 不打开窗口、不进菜单栏，改完 UI 跑一下即可看渲染结果和布局数据。
set -euo pipefail
cd "$(dirname "$0")/.."

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# FirstLightCore 提供全部界面代码；其 main.swift 已拆到可执行 target，
# 因此 harness 的 main.swift 作为唯一入口参与编译
ls Sources/FirstLightCore/*.swift \
  | xargs swiftc -o "$WORK/render" Scripts/preview/main.swift
"$WORK/render"
echo "🖼  预览已输出: /tmp/fl-main.png"

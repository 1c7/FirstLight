#!/bin/bash
# Builds FirstLight in release mode and assembles it into a proper
# FirstLight.app bundle, then ad-hoc code-signs it so Gatekeeper doesn't
# block launching it on this machine.
#
# No sandbox entitlements are applied on purpose: this app reads the
# ambient light sensor via a fully public IOKit registry API call
# reading an undocumented property ("CurrentLux" on the AppleSPUVD6286
# driver node -- see doc/1-传感器读取原理.md) and needs to run
# unsandboxed. Do not add an entitlements file/App Sandbox capability
# here without checking that sensor access still works -- sandboxing can
# silently break it.
#
# Usage: Packaging/build.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="FirstLight"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_BUNDLE="$ROOT_DIR/$APP_NAME.app"

echo "==> swift build -c release"
cd "$ROOT_DIR"
swift build -c release

echo "==> Assembling $APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_BUNDLE/Contents/Info.plist"
cp "$ROOT_DIR/Packaging/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
if [ -d "$ROOT_DIR/Packaging/Resources" ]; then
    cp -R "$ROOT_DIR/Packaging/Resources/"* "$APP_BUNDLE/Contents/Resources/"
fi

echo "==> ad-hoc code signing"
codesign --force --deep --sign - "$APP_BUNDLE"

# Finder caches icons aggressively -- nudge it to notice the new bundle
# icon instead of showing a stale/generic one.
touch "$APP_BUNDLE"

echo "==> done: $APP_BUNDLE"
echo "Run it with: open \"$APP_BUNDLE\""

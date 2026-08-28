#!/bin/bash
# Builds LightDose in release mode and assembles it into a proper
# LightDose.app bundle, then ad-hoc code-signs it so Gatekeeper doesn't
# block launching it on this machine.
#
# No sandbox entitlements are applied on purpose: this app reads the
# ambient light sensor via a private IOKit registry property
# ("CurrentLux" on the AppleSPUVD6286 driver node -- see
# Sources/LightDose/AmbientLightSensor.swift for details) and needs to
# run unsandboxed. Do not add an entitlements file/App Sandbox capability
# here without checking that sensor access still works -- sandboxing can
# silently break it.
#
# Usage: Packaging/build.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="LightDose"
BUILD_DIR="$ROOT_DIR/.build/release"
APP_BUNDLE="$ROOT_DIR/$APP_NAME.app"

echo "==> swift build -c release"
cd "$ROOT_DIR"
swift build -c release

echo "==> Assembling $APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/Packaging/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

echo "==> ad-hoc code signing"
codesign --force --deep --sign - "$APP_BUNDLE"

echo "==> done: $APP_BUNDLE"
echo "Run it with: open \"$APP_BUNDLE\""

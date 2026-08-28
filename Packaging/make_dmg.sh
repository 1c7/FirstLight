#!/bin/bash
# Builds LightDose.app (via build.sh) and packages it into a distributable
# LightDose.dmg -- a disk image with the .app plus a shortcut to
# /Applications, the standard drag-to-install experience on macOS.
#
# This does NOT make the app notarized or Developer-ID signed -- it's
# still ad-hoc signed (see build.sh). Anyone opening the DMG on a
# different Mac will still see Gatekeeper's "unidentified developer"
# warning the first time and needs to right-click > Open once to bypass
# it. That's an accepted tradeoff for a free, unpaid personal project --
# see doc/3-项目结构与开发说明.md.
#
# Usage: Packaging/make_dmg.sh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="LightDose"
APP_BUNDLE="$ROOT_DIR/$APP_NAME.app"
DMG_PATH="$ROOT_DIR/$APP_NAME.dmg"
STAGING_DIR="$(mktemp -d)"

echo "==> Building $APP_NAME.app"
"$ROOT_DIR/Packaging/build.sh"

echo "==> Staging DMG contents"
cp -R "$APP_BUNDLE" "$STAGING_DIR/$APP_NAME.app"
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creating $APP_NAME.dmg"
rm -f "$DMG_PATH"
hdiutil create \
  -volname "$APP_NAME" \
  -srcfolder "$STAGING_DIR" \
  -ov -format UDZO \
  "$DMG_PATH"

rm -rf "$STAGING_DIR"

echo "==> done: $DMG_PATH"
echo "Anyone can now: open $APP_NAME.dmg, drag $APP_NAME.app into Applications,"
echo "then right-click > Open once to get past the unidentified-developer warning."

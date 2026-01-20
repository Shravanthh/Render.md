#!/bin/bash
set -e

APP_NAME="Render.md"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_PATH="${APP_NAME}.app"

echo "🔨 Building release binary..."
swift build -c release

echo "📦 Creating app bundle..."
./scripts/build-app.sh

echo "🗂️  Preparing distribution..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "💾 Creating DMG..."
# Create temporary DMG directory
TMP_DMG_DIR=$(mktemp -d)
cp -R "$APP_PATH" "$TMP_DMG_DIR/"
ln -s /Applications "$TMP_DMG_DIR/Applications"

# Create DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TMP_DMG_DIR" \
    -ov -format UDZO \
    "$DIST_DIR/$DMG_NAME.dmg"

# Cleanup
rm -rf "$TMP_DMG_DIR"

echo "✅ DMG created: $DIST_DIR/$DMG_NAME.dmg"
echo "📊 Size: $(du -h "$DIST_DIR/$DMG_NAME.dmg" | cut -f1)"

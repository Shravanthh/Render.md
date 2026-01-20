#!/bin/bash
set -e

APP_NAME="Render.md"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"
BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_PATH="${APP_NAME}.app"
TMP_DMG_DIR=$(mktemp -d)

echo "🔨 Building release binary..."
swift build -c release

echo "📦 Creating app bundle..."
./scripts/build-app.sh

echo "🗂️  Preparing distribution..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

echo "💾 Creating DMG..."
# Copy app to temp directory
cp -R "$APP_PATH" "$TMP_DMG_DIR/"
ln -s /Applications "$TMP_DMG_DIR/Applications"

# Create DMG directly
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TMP_DMG_DIR" \
    -ov -format UDZO \
    "$DIST_DIR/$DMG_NAME.dmg"

# Add icon to DMG
if [ -f "AppIcon.icns" ]; then
    sips -i AppIcon.icns > /dev/null
    DeRez -only icns AppIcon.icns > /tmp/tmpicns.rsrc
    Rez -append /tmp/tmpicns.rsrc -o "$DIST_DIR/$DMG_NAME.dmg"
    SetFile -a C "$DIST_DIR/$DMG_NAME.dmg"
    rm /tmp/tmpicns.rsrc
fi

# Cleanup
rm -rf "$TMP_DMG_DIR"

echo "✅ DMG created: $DIST_DIR/$DMG_NAME.dmg"
echo "📊 Size: $(du -h "$DIST_DIR/$DMG_NAME.dmg" | cut -f1)"

#!/bin/bash
set -e

APP_NAME="Render.md"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}"
DIST_DIR="dist"
APP_PATH="${APP_NAME}.app"

echo "🔨 Building release binary..."
swift build -c release

echo "📦 Creating app bundle..."
./scripts/build-app.sh

echo "🗂️  Preparing distribution..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/dmg-temp"

# Copy app and create symlink
cp -R "$APP_PATH" "$DIST_DIR/dmg-temp/"
ln -s /Applications "$DIST_DIR/dmg-temp/Applications"

# Create DS_Store for layout
mkdir -p "$DIST_DIR/dmg-temp/.background"

echo "💾 Creating DMG..."
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$DIST_DIR/dmg-temp" \
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
rm -rf "$DIST_DIR/dmg-temp"

echo "✅ DMG created: $DIST_DIR/$DMG_NAME.dmg"
echo "📊 Size: $(du -h "$DIST_DIR/$DMG_NAME.dmg" | cut -f1)"

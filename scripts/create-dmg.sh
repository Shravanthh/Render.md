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

# Create Applications symlink
ln -s /Applications "$TMP_DMG_DIR/Applications"

# Create temporary DMG
TMP_DMG="$DIST_DIR/tmp-$DMG_NAME.dmg"
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$TMP_DMG_DIR" \
    -ov -format UDRW \
    "$TMP_DMG"

# Mount it
MOUNT_DIR="/Volumes/$APP_NAME"
hdiutil attach "$TMP_DMG" -mountpoint "$MOUNT_DIR"

# Set window properties
echo '
   tell application "Finder"
     tell disk "'$APP_NAME'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 1000, 500}
           set viewOptions to the icon view options of container window
           set arrangement of viewOptions to not arranged
           set icon size of viewOptions to 128
           set position of item "'$APP_NAME'.app" of container window to {150, 200}
           set position of item "Applications" of container window to {450, 200}
           close
           open
           update without registering applications
           delay 2
     end tell
   end tell
' | osascript || true

# Unmount
hdiutil detach "$MOUNT_DIR"

# Convert to compressed
hdiutil convert "$TMP_DMG" -format UDZO -o "$DIST_DIR/$DMG_NAME.dmg"
rm "$TMP_DMG"

# Cleanup
rm -rf "$TMP_DMG_DIR"

echo "✅ DMG created: $DIST_DIR/$DMG_NAME.dmg"
echo "📊 Size: $(du -h "$DIST_DIR/$DMG_NAME.dmg" | cut -f1)"

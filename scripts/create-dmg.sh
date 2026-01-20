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
    -ov -format UDRW \
    "$DIST_DIR/temp.dmg"

# Mount and customize
MOUNT_DIR="/Volumes/$APP_NAME"
hdiutil attach "$DIST_DIR/temp.dmg" -mountpoint "$MOUNT_DIR" -nobrowse

# Apply layout with AppleScript
osascript <<EOF
tell application "Finder"
    tell disk "$APP_NAME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {100, 100, 700, 500}
        set theViewOptions to the icon view options of container window
        set arrangement of theViewOptions to not arranged
        set icon size of theViewOptions to 128
        set background color of theViewOptions to {30, 30, 40}
        delay 1
        set position of item "$APP_NAME.app" of container window to {150, 180}
        set position of item "Applications" of container window to {450, 180}
        update without registering applications
        delay 2
        close
    end tell
end tell
EOF

sleep 2

# Unmount with retries
for i in {1..5}; do
    if hdiutil detach "$MOUNT_DIR" -force 2>/dev/null; then
        break
    fi
    sleep 1
done

sleep 3

# Convert to compressed with retries
for i in {1..5}; do
    if hdiutil convert "$DIST_DIR/temp.dmg" -format UDZO -o "$DIST_DIR/$DMG_NAME.dmg" 2>/dev/null; then
        break
    fi
    sleep 2
done

rm -f "$DIST_DIR/temp.dmg"

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

#!/bin/bash
set -e

echo "Building Render.md..."
swift build -c release

echo "Creating app bundle..."
APP_NAME="Render.md"
BUNDLE_PATH="$APP_NAME.app"

rm -rf "$BUNDLE_PATH"
mkdir -p "$BUNDLE_PATH/Contents/MacOS"
mkdir -p "$BUNDLE_PATH/Contents/Resources"

cp .build/release/RenderMD "$BUNDLE_PATH/Contents/MacOS/RenderMD"

# Copy icon
if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$BUNDLE_PATH/Contents/Resources/"
fi

cat > "$BUNDLE_PATH/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>Render.md</string>
    <key>CFBundleDisplayName</key><string>Render.md</string>
    <key>CFBundleIdentifier</key><string>com.rendermd.app</string>
    <key>CFBundleVersion</key><string>1.0.0</string>
    <key>CFBundleShortVersionString</key><string>1.0.0</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleExecutable</key><string>RenderMD</string>
    <key>CFBundleIconFile</key><string>AppIcon</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key><string>Markdown</string>
            <key>CFBundleTypeExtensions</key><array><string>md</string><string>markdown</string></array>
            <key>CFBundleTypeRole</key><string>Editor</string>
        </dict>
    </array>
</dict>
</plist>
PLIST

echo "✅ Built: $BUNDLE_PATH"

# Clean extended attributes and ad-hoc sign
xattr -cr "$BUNDLE_PATH"
codesign --force --deep --sign - "$BUNDLE_PATH"
echo "🔏 Signed: $BUNDLE_PATH"

echo "To install: cp -R $BUNDLE_PATH /Applications/"

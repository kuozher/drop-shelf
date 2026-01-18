#!/bin/bash

# DropShelf Packaging Script
# This script bundles the Swift Package into a standalone macOS .app

APP_NAME="DropShelf"
BUILD_PATH=".build/release"
APP_BUNDLE="$APP_NAME.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

echo "🚀 Starting build for $APP_NAME..."

# 1. Build in Release mode
swift build -c release

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Please check your code."
    exit 1
fi

echo "📦 Creating App Bundle structure..."

# 2. Create folder structure
mkdir -p "$MACOS_DIR"
mkdir -p "$RESOURCES_DIR"

# 3. Copy the executable
cp "$BUILD_PATH/$APP_NAME" "$MACOS_DIR/"

# 3a. Process App Icon
ICON_SOURCE="assets/icon.png"
ICON_DEST="$RESOURCES_DIR/AppIcon.icns"

if [ -f "$ICON_SOURCE" ]; then
    echo "🎨 processing AppIcon from $ICON_SOURCE..."
    ICONSET_DIR="AppIcon.iconset"
    mkdir -p "$ICONSET_DIR"

    # Generate standard icon sizes
    sips -z 16 16     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
    sips -z 32 32     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
    sips -z 64 64     "$ICON_SOURCE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
    sips -z 128 128   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
    sips -z 256 256   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
    sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
    sips -z 512 512   "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
    sips -z 1024 1024 "$ICON_SOURCE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

    # Convert to .icns
    iconutil -c icns "$ICONSET_DIR" -o "$ICON_DEST"
    rm -rf "$ICONSET_DIR"
    echo "✅ AppIcon.icns created."
else
    echo "⚠️  No icon found at $ICON_SOURCE. Using default generic icon."
fi

# 4. Generate Info.plist
cat > "$CONTENTS_DIR/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.erickuo.DropShelf</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

# 5. Codesign (Ad-hoc signing with entitlements)
# This removes repetitive security prompts for files and app launch
echo "🔐 Signing App with entitlements..."
# Clean resource forks/detritus to prevent signing errors
xattr -cr "$APP_BUNDLE"
codesign --force --options runtime --sign - --entitlements DropShelf.entitlements "$APP_BUNDLE"

if [ $? -ne 0 ]; then
    echo "❌ Signing failed."
    exit 1
fi

echo "✅ Success! $APP_BUNDLE has been created and signed."
echo "👉 You can now move $APP_BUNDLE to your Applications folder or double-click it to run."

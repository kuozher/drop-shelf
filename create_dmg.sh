#!/bin/bash

# DropShelf DMG Creation Script
# This script bundles the signed DropShelf.app into a professional DMG image.

APP_NAME="DropShelf"
APP_BUNDLE="$APP_NAME.app"
VERSION=$(grep -A 1 "CFBundleShortVersionString" "$APP_BUNDLE/Contents/Info.plist" | grep string | sed 's/<[^>]*>//g' | xargs)
if [ -z "$VERSION" ]; then
    VERSION="1.1.2"
fi
DMG_NAME="${APP_NAME}-v${VERSION}.dmg"
STAGING_DIR="dmg_staging"

echo "🚀 Preparing DMG for $APP_NAME..."

# 1. Ensure the app is built and signed
if [ ! -d "$APP_BUNDLE" ]; then
    echo "❌ $APP_BUNDLE not found. Please run ./package.sh first."
    exit 1
fi

# 2. Setup Staging Area
echo "📂 Setting up staging directory..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
cp -R "$APP_BUNDLE" "$STAGING_DIR/"

# 3. Create Applications Symlink
echo "🔗 Adding Applications shortcut..."
ln -s /Applications "$STAGING_DIR/Applications"

# 4. Create DMG
echo "💿 Creating Disk Image..."
rm -f "$DMG_NAME"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

# 5. Cleanup
rm -rf "$STAGING_DIR"

echo "✅ Success! $DMG_NAME has been created."
echo "👉 You can now share $DMG_NAME with other users."
echo "💡 Reminder: First-time users on other Macs must Right-Click -> Open the app to bypass Gatekeeper (unless notarized)."

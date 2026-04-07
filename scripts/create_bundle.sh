#!/bin/bash
set -e

PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$PROJECT/가계부.app"
ASSETS="$PROJECT/Sources/Gakyebu/Assets.xcassets/AppIcon.appiconset"
BINARY="$PROJECT/.build/Gakyebu-universal"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"
mkdir -p "$APP/Contents/Frameworks"

cp "$BINARY" "$APP/Contents/MacOS/Gakyebu"

# icns 생성
ICONSET="/tmp/AppIcon.iconset"
rm -rf "$ICONSET"
mkdir -p "$ICONSET"
ICON="$ASSETS/가계부아이콘-iOS-Default-1024x1024@1x.png"
cp "$ICON" "$ICONSET/icon_16x16.png"
cp "$ICON" "$ICONSET/icon_16x16@2x.png"
cp "$ICON" "$ICONSET/icon_32x32.png"
cp "$ICON" "$ICONSET/icon_32x32@2x.png"
cp "$ICON" "$ICONSET/icon_128x128.png"
cp "$ICON" "$ICONSET/icon_128x128@2x.png"
cp "$ICON" "$ICONSET/icon_256x256.png"
cp "$ICON" "$ICONSET/icon_256x256@2x.png"
cp "$ICON" "$ICONSET/icon_512x512.png"
cp "$ICON" "$ICONSET/icon_512x512@2x.png"
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"

cp "$PROJECT/Info.plist" "$APP/Contents/Info.plist"

# Sparkle.framework 임베드
cp -R "$PROJECT/.build/arm64-apple-macosx/release/Sparkle.framework" "$APP/Contents/Frameworks/"

xattr -cr "$APP"
codesign --force --deep --sign - "$APP"

echo "✅ 앱 번들 생성 완료: $APP"

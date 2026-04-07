#!/bin/bash
set -e

PROJECT="$(cd "$(dirname "$0")" && pwd)"
APP="$PROJECT/가계부.app"
ASSETS="$PROJECT/Sources/Gakyebu/Assets.xcassets/AppIcon.appiconset"

echo "🔨 빌드 중..."
cd "$PROJECT"
swift build -c release 2>&1

BINARY="$PROJECT/.build/release/Gakyebu"

echo "📦 앱 번들 생성 중..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

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

# Sparkle.framework 임베드
mkdir -p "$APP/Contents/Frameworks"
cp -R "$PROJECT/.build/release/Sparkle.framework" "$APP/Contents/Frameworks/"

cat > "$APP/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Gakyebu</string>
    <key>CFBundleIdentifier</key>
    <string>com.minhyeok.gakyebu</string>
    <key>CFBundleName</key>
    <string>가계부</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

# 서명 및 Dock 캐시 갱신
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP"

echo ""
echo "✅ 완료! 가계부.app"
open "$PROJECT"

#!/bin/bash
set -e

PROJECT="$(cd "$(dirname "$0")" && pwd)"
VERSION=$1

if [ -z "$VERSION" ]; then
    echo "사용법: ./release.sh 1.0.1"
    exit 1
fi

echo "🚀 버전 $VERSION 릴리즈 시작..."

# Info.plist 버전 업데이트
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PROJECT/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PROJECT/Info.plist"

# 빌드
bash "$PROJECT/build_app.sh"

# zip 압축
cd "$PROJECT"
zip -r "가계부.zip" "가계부.app"

# appcast.xml 업데이트
DATE=$(date -R)
cat > "$PROJECT/docs/appcast.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>가계부 업데이트</title>
        <link>https://park-seaweed.github.io/budget-planner/appcast.xml</link>
        <description>가계부 앱 업데이트 피드</description>
        <item>
            <title>버전 $VERSION</title>
            <pubDate>$DATE</pubDate>
            <sparkle:version>$VERSION</sparkle:version>
            <sparkle:shortVersionString>$VERSION</sparkle:shortVersionString>
            <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
            <enclosure
                url="https://github.com/Park-Seaweed/budget-planner/releases/download/v${VERSION}/가계부.zip"
                sparkle:version="$VERSION"
                type="application/octet-stream"
            />
        </item>
    </channel>
</rss>
EOF

# git commit & push
git add -A
git commit -m "Release v$VERSION"
git tag "v$VERSION"
git push origin main --tags

echo ""
echo "✅ v$VERSION 배포 완료!"
echo "👉 GitHub에서 Release 만들고 가계부.zip 업로드하세요:"
echo "   https://github.com/Park-Seaweed/budget-planner/releases/new?tag=v${VERSION}"

#!/bin/bash
set -e

VERSION=$1
if [ -z "$VERSION" ]; then
  echo "사용법: update_appcast.sh <version>"
  exit 1
fi

DATE=$(date -R)
PROJECT="$(cd "$(dirname "$0")/.." && pwd)"

cat > "$PROJECT/docs/appcast.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
    <channel>
        <title>가계부 업데이트</title>
        <link>https://raw.githubusercontent.com/Park-Seaweed/budget-planner/main/docs/appcast.xml</link>
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

echo "✅ appcast.xml 업데이트 완료 (v$VERSION)"

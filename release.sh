#!/bin/bash
set -e

PROJECT="$(cd "$(dirname "$0")" && pwd)"
VERSION=$1

if [ -z "$VERSION" ]; then
    echo "사용법: ./release.sh 1.0.1"
    exit 1
fi

# Info.plist 버전 업데이트
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PROJECT/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PROJECT/Info.plist"

git add Info.plist
git commit -m "Release v$VERSION"
git push origin main

echo "✅ push 완료 → GitHub Actions가 자동으로 빌드 & 배포해요"
echo "   https://github.com/Park-Seaweed/budget-planner/actions"

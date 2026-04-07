#!/bin/bash
set -e

PROJECT="$(cd "$(dirname "$0")" && pwd)"
VERSION=$1

if [ -z "$VERSION" ]; then
    echo "사용법: ./release.sh 1.0.1"
    exit 1
fi

echo "🚀 v$VERSION 릴리즈 준비..."

# Info.plist 버전 업데이트
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" "$PROJECT/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$PROJECT/Info.plist"

# git commit & tag push → GitHub Actions가 나머지 처리
git add Info.plist
git commit -m "Release v$VERSION"
git tag "v$VERSION"
git push origin main --tags

echo ""
echo "✅ 태그 push 완료!"
echo "👉 GitHub Actions에서 빌드 진행 중:"
echo "   https://github.com/Park-Seaweed/budget-planner/actions"

#!/bin/bash
set -e

swift build -c release --arch arm64 \
  -Xlinker -rpath -Xlinker @loader_path/../Frameworks

swift build -c release --arch x86_64 \
  -Xlinker -rpath -Xlinker @loader_path/../Frameworks

lipo -create \
  .build/arm64-apple-macosx/release/Gakyebu \
  .build/x86_64-apple-macosx/release/Gakyebu \
  -output .build/Gakyebu-universal

echo "✅ Universal binary 생성 완료"

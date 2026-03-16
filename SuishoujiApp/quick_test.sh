#!/bin/bash
echo "🧪 快速构建和运行测试"
echo ""

# 1. 构建
echo "📦 1. 构建项目..."
xcodebuild -project Suishouji.xcodeproj \
  -scheme Suishouji \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  clean build 2>&1 | grep -E "(BUILD|error:|warning:)" | tail -10

echo ""

# 2. 检查构建产物
echo "📦 2. 检查构建产物..."
if [ -f "/Users/caiji/Library/Developer/Xcode/DerivedData/Suishouji-*/Build/Products/Debug-iphonesimulator/Suishouji.app" ]; then
    echo "   ✅ App 构建成功"
else
    echo "   ❌ App 未找到"
fi

echo ""
echo "✅ 测试完成！"

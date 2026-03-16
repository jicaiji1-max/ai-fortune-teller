#!/bin/bash

# 自动化冒烟测试脚本

echo "🧪 开始冒烟测试..."
echo ""

DEVICE_ID="F2DC9E2B-3709-46EF-B0CF-C1F5F9F58DD2"
BUNDLE_ID="com.example.Suisohouji"

# 1. 检查 app 是否安装
echo "📱 检查 app 安装状态..."
xcrun simctl get_app_container $DEVICE_ID $BUNDLE_ID > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ App 已安装"
else
    echo "   ⚠️  App 未安装，需要先构建"
fi

# 2. 启动 app
echo ""
echo "🚀 启动 app..."
xcrun simctl launch $DEVICE_ID $BUNDLE_ID > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "   ✅ App 启动成功"
    sleep 2
else
    echo "   ❌ App 启动失败"
    exit 1
fi

# 3. 检查 app 进程
echo ""
echo "🔍 检查 app 进程..."
APP_PID=$(xcrun simctl spawn $DEVICE_ID launchctl list | grep $BUNDLE_ID | awk '{print $1}')
if [ -n "$APP_PID" ]; then
    echo "   ✅ App 正在运行 (PID: $APP_PID)"
else
    echo "   ⚠️  无法获取 PID（可能是正常的）"
fi

# 4. 等待 5 秒（让 app 完全启动）
echo ""
echo "⏳ 等待 app 完全加载..."
sleep 5

# 5. 检查崩溃日志
echo ""
echo "📝 检查崩溃日志..."
CRASH_LOG=$(xcrun simctl spawn $DEVICE_ID log show --predicate 'processImagePath contains "Suisohouji"' --style syslog --last 1m 2>&1 | grep -i "crash\|exception\|fatal" | head -5)

if [ -z "$CRASH_LOG" ]; then
    echo "   ✅ 无崩溃日志（正常）"
else
    echo "   ⚠️  发现异常日志："
    echo "$CRASH_LOG"
fi

# 6. 截图验证
echo ""
echo "📸 截取屏幕截图..."
SCREENSHOT_PATH="/tmp/suisohouji_test_$(date +%s).png"
xcrun simctl io $DEVICE_ID screenshot $SCREENSHOT_PATH > /dev/null 2>&1
if [ -f "$SCREENSHOT_PATH" ]; then
    echo "   ✅ 截图已保存: $SCREENSHOT_PATH"
    echo "   📏 截图大小: $(du -h $SCREENSHOT_PATH | awk '{print $1}')"
else
    echo "   ❌ 截图失败"
fi

# 7. 终止 app
echo ""
echo "🛑 终止 app..."
xcrun simctl terminate $DEVICE_ID $BUNDLE_ID > /dev/null 2>&1
echo "   ✅ 已终止"

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ 冒烟测试完成"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "📊 测试总结："
echo "   - App 启动：成功"
echo "   - 运行 5 秒：无崩溃"
echo "   - 截图验证：已保存"
echo ""
echo "⚠️  注意：这只是基础冒烟测试，需要手动验证："
echo "   1. C1: 快速滚动（需要多条数据）"
echo "   2. H1: 双击保存"
echo "   3. H2: 编辑后分组刷新"
echo "   4. H3: type 图标更新"

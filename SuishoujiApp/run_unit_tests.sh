#!/bin/bash
# 不使用 set -e，让所有测试都运行

echo "🧪 随手记 App - 单元测试脚本"
echo "================================"
echo ""

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PASS_COUNT=0
FAIL_COUNT=0

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    echo -n "📋 测试：$test_name ... "
    
    if eval "$test_command" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ 通过${NC}"
        ((PASS_COUNT++))
    else
        echo -e "${RED}❌ 失败${NC}"
        ((FAIL_COUNT++))
    fi
}

echo "1️⃣  编译检查..."
echo ""

# 测试 1：Swift 语法检查
run_test "Note.swift 语法检查" "swiftc -parse Note.swift"
run_test "NoteRow.swift 语法检查" "swiftc -parse NoteRow.swift"
run_test "ContentView.swift 语法检查" "swiftc -parse ContentView.swift"
run_test "CameraView.swift 语法检查" "swiftc -parse CameraView.swift"
run_test "TextEditorView.swift 语法检查" "swiftc -parse TextEditorView.swift"

echo ""
echo "2️⃣  构建检查..."
echo ""

# 测试 2：Xcode 构建
run_test "Xcode 项目生成" "test -f Suishouji.xcodeproj/project.pbxproj"
run_test "Xcode 构建" "xcodebuild -project Suishouji.xcodeproj -scheme Suishouji -destination 'platform=iOS Simulator,name=iPhone 17' build"

echo ""
echo "3️⃣  代码规范检查..."
echo ""

# 测试 3：代码规范
run_test "NoteRow 有 onDelete 回调" "grep -q 'var onDelete: () -> Void' NoteRow.swift"
run_test "NoteRow 有长按删除" "grep -q 'onLongPressGesture' NoteRow.swift"
run_test "NoteRow 有删除确认" "grep -q 'alert.*确认删除' NoteRow.swift"
run_test "NoteRow 有删除按钮" "grep -q 'Button(role: .destructive)' NoteRow.swift"
run_test "CameraView 有 MainActor" "grep -q '@MainActor' CameraView.swift"

echo ""
echo "4️⃣  功能完整性检查..."
echo ""

# 测试 4：功能完整性
run_test "三种删除方式实现" "grep -q 'swipeActions' ContentView.swift && grep -q 'onLongPressGesture' NoteRow.swift && grep -q 'Button.*destructive' NoteRow.swift"
run_test "删除确认对话框" "grep -q 'alert.*确认删除' NoteRow.swift"
run_test "UIKit 导入正确" "grep -q 'import UIKit' NoteRow.swift"

echo ""
echo "================================"
echo "📊 测试结果汇总"
echo "================================"
echo -e "✅ 通过：${GREEN}${PASS_COUNT}${NC}"
echo -e "❌ 失败：${RED}${FAIL_COUNT}${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}🎉 所有测试通过！${NC}"
    exit 0
else
    echo -e "${RED}⚠️  有 ${FAIL_COUNT} 个测试失败，请检查${NC}"
    exit 1
fi

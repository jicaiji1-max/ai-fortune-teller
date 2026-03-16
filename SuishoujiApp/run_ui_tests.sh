#!/bin/bash

#
# 随手记 App - UI 测试运行脚本
# 基于 88 个测试用例
#

set -e

echo "🚀 随手记 App - UI 测试"
echo "================================"

# 配置
PROJECT_NAME="Suisohouji"
SCHEME_NAME="Suisohouji"
DEVICE_NAME="iPhone 15"
OS_VERSION="17.0"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印函数
print_info() {
    echo -e "${GREEN}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查 Xcode 是否安装
check_xcode() {
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode 未安装或未正确配置"
        exit 1
    fi
    print_info "Xcode 已安装"
}

# 列出可用的模拟器
list_simulators() {
    print_info "可用的模拟器："
    xcrun simctl list devices available | grep -E "iPhone|iPad" | head -10
}

# 运行所有 UI 测试
run_all_tests() {
    print_info "运行所有 UI 测试..."
    
    xcodebuild test \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME_NAME}" \
        -destination "platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_VERSION}" \
        -only-testing:"${SCHEME_NAME}UITests" \
        -resultBundlePath "TestResults/AllTests" \
        | xcpretty || {
            print_error "测试失败"
            exit 1
        }
    
    print_info "✅ 所有测试完成"
}

# 运行特定流程的测试
run_flow_tests() {
    local flow_name=$1
    
    print_info "运行流程 $flow_name 测试..."
    
    xcodebuild test \
        -project "${PROJECT_NAME}.xcodeproj" \
        -scheme "${SCHEME_NAME}" \
        -destination "platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_VERSION}" \
        -only-testing:"${SCHEME_NAME}UITests/Flow${flow_name}_*" \
        -resultBundlePath "TestResults/Flow${flow_name}" \
        | xcpretty || {
            print_error "流程 $flow_name 测试失败"
            exit 1
        }
}

# 运行 P0 优先级测试
run_p0_tests() {
    print_info "运行 P0 优先级测试（核心功能）..."
    
    # P0 测试用例列表
    local p0_tests=(
        "Flow1_PhotoUploadTests/testTC1_01_PhotoAndSave"
        "Flow1_PhotoUploadTests/testTC1_02_PhotoWithDescription"
        "Flow2_AlbumMultiSelectTests/testTC2_01_SelectOnePhoto"
        "Flow2_AlbumMultiSelectTests/testTC2_02_SelectNinePhotos"
        "Flow2_AlbumMultiSelectTests/testTC2_03_SelectThreePhotos"
        "Flow3_TextNoteTests/testTC3_01_CreateTextNote"
        "Flow4_EditTests/testTC4_1_01_ModifyDescriptionOnly"
        "Flow4_EditTests/testTC4_1_02_ReplacePhotoOnly"
        "Flow5_DeleteTests/testTC5_01_ClickDeleteButton"
        "Flow5_DeleteTests/testTC5_2_03_ConfirmDelete"
        "Flow6_SaveToAlbumTests/testTC6_03_AllowPermissionAndSave"
    )
    
    for test in "${p0_tests[@]}"; do
        print_info "运行：$test"
        
        xcodebuild test \
            -project "${PROJECT_NAME}.xcodeproj" \
            -scheme "${SCHEME_NAME}" \
            -destination "platform=iOS Simulator,name=${DEVICE_NAME},OS=${OS_VERSION}" \
            -only-testing:"${SCHEME_NAME}UITests/${test}" \
            -resultBundlePath "TestResults/P0_$(basename $test)" \
            | xcpretty || {
                print_warning "测试失败：$test"
            }
    done
    
    print_info "✅ P0 测试完成"
}

# 生成测试报告
generate_report() {
    print_info "生成测试报告..."
    
    # 创建报告目录
    mkdir -p TestResults/Reports
    
    # 生成 HTML 报告（需要 xcresulttool）
    if command -v xcrun &> /dev/null; then
        xcrun xcresulttool get \
            --path TestResults/AllTests.xcresult \
            --format json \
            > TestResults/Reports/result.json 2>/dev/null || true
    fi
    
    print_info "报告已生成到 TestResults/Reports/"
}

# 清理测试数据
cleanup() {
    print_info "清理测试数据..."
    
    # 删除结果目录
    rm -rf TestResults
    
    # 重置模拟器
    xcrun simctl erase all 2>/dev/null || true
    
    print_info "✅ 清理完成"
}

# 显示帮助
show_help() {
    echo "用法：$0 [选项]"
    echo ""
    echo "选项:"
    echo "  all          运行所有测试"
    echo "  flow N       运行特定流程测试（1-6）"
    echo "  p0           运行 P0 优先级测试"
    echo "  report       生成测试报告"
    echo "  cleanup      清理测试数据"
    echo "  help         显示帮助"
    echo ""
    echo "示例:"
    echo "  $0 all       # 运行所有测试"
    echo "  $0 flow 1    # 运行流程 1 测试"
    echo "  $0 p0        # 运行 P0 测试"
}

# 主函数
main() {
    check_xcode
    
    case "${1:-all}" in
        all)
            run_all_tests
            generate_report
            ;;
        flow)
            if [ -z "$2" ]; then
                print_error "请指定流程编号（1-6）"
                exit 1
            fi
            run_flow_tests "$2"
            ;;
        p0)
            run_p0_tests
            ;;
        report)
            generate_report
            ;;
        cleanup)
            cleanup
            ;;
        help|-h|--help)
            show_help
            ;;
        *)
            print_error "未知选项：$1"
            show_help
            exit 1
            ;;
    esac
}

# 执行
main "$@"

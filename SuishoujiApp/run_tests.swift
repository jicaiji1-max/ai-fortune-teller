#!/usr/bin/env swift

import Foundation
import UIKit

// 测试结果统计
var totalTests = 0
var passedTests = 0
var failedTests = 0

// 辅助函数
func runTest(name: String, test: () throws -> Void) {
    totalTests += 1
    print("🧪 运行测试: \(name)")
    do {
        try test()
        passedTests += 1
        print("   ✅ 通过\n")
    } catch {
        failedTests += 1
        print("   ❌ 失败: \(error)\n")
    }
}

func assertEqual<T: Equatable>(_ value: T, _ expected: T, _ message: String = "") throws {
    if value != expected {
        throw NSError(domain: "TestError", code: 1, 
                     userInfo: [NSLocalizedDescriptionKey: "期望 \(expected)，实际 \(value). \(message)"])
    }
}

func assertNotNil<T>(_ value: T?, _ message: String = "") throws {
    if value == nil {
        throw NSError(domain: "TestError", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "值不应为 nil. \(message)"])
    }
}

func assertTrue(_ condition: Bool, _ message: String = "") throws {
    if !condition {
        throw NSError(domain: "TestError", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "条件应为 true. \(message)"])
    }
}

func assertLessThan(_ value: Double, _ limit: Double, _ message: String = "") throws {
    if value >= limit {
        throw NSError(domain: "TestError", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "\(value) 应小于 \(limit). \(message)"])
    }
}

// ============================================================
// TC-034: 图片压缩基础测试
// ============================================================

runTest(name: "TC-034-1: 创建测试图片") {
    let size = CGSize(width: 1000, height: 1000)
    let renderer = UIGraphicsImageRenderer(size: size)
    let testImage = renderer.image { context in
        UIColor.blue.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    
    try assertNotNil(testImage, "应该能创建测试图片")
    try assertEqual(testImage.size.width, 1000.0, "图片宽度")
    try assertEqual(testImage.size.height, 1000.0, "图片高度")
}

runTest(name: "TC-034-2: JPEG 压缩") {
    let size = CGSize(width: 2000, height: 2000)
    let renderer = UIGraphicsImageRenderer(size: size)
    let testImage = renderer.image { context in
        UIColor.red.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    
    guard let originalData = testImage.jpegData(compressionQuality: 1.0) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建原始数据"])
    }
    
    guard let compressedData = testImage.jpegData(compressionQuality: 0.6) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法压缩"])
    }
    
    print("   📊 原始大小: \(originalData.count) bytes")
    print("   📊 压缩后: \(compressedData.count) bytes")
    print("   📊 压缩率: \(String(format: "%.1f", Double(compressedData.count) / Double(originalData.count) * 100))%")
    
    try assertTrue(compressedData.count < originalData.count, "压缩后应该更小")
}

runTest(name: "TC-034-3: 图片缩放") {
    let size = CGSize(width: 3000, height: 2000)
    let renderer = UIGraphicsImageRenderer(size: size)
    let testImage = renderer.image { context in
        UIColor.green.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    
    // 缩放到 1024x1024（保持宽高比）
    let targetSize = CGSize(width: 1024, height: 1024)
    let scale = min(targetSize.width / size.width, targetSize.height / size.height)
    let scaledSize = CGSize(
        width: size.width * scale,
        height: size.height * scale
    )
    
    let renderer2 = UIGraphicsImageRenderer(size: scaledSize)
    let scaledImage = renderer2.image { _ in
        testImage.draw(in: CGRect(origin: .zero, size: scaledSize))
    }
    
    print("   📊 原始尺寸: \(size.width) x \(size.height)")
    print("   📊 缩放后: \(scaledImage.size.width) x \(scaledImage.size.height)")
    
    try assertTrue(scaledImage.size.width <= 1024, "宽度应该 ≤ 1024")
    try assertTrue(scaledImage.size.height <= 1024, "高度应该 ≤ 1024")
}

// ============================================================
// TC-035: 日期格式化测试
// ============================================================

runTest(name: "TC-035-1: 时间格式化") {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.locale = Locale(identifier: "zh_CN")
    
    let calendar = Calendar.current
    let components = DateComponents(year: 2026, month: 3, day: 10, hour: 14, minute: 30)
    guard let testDate = calendar.date(from: components) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建日期"])
    }
    
    let result = formatter.string(from: testDate)
    print("   📅 格式化结果: \(result)")
    
    try assertEqual(result, "14:30", "时间格式")
}

runTest(name: "TC-035-2: 日期分组（今天）") {
    let calendar = Calendar.current
    let now = Date()
    
    let isToday = calendar.isDateInToday(now)
    print("   📅 当前时间是今天: \(isToday)")
    
    try assertTrue(isToday, "当前时间应该是今天")
}

runTest(name: "TC-035-3: 日期分组（昨天）") {
    let calendar = Calendar.current
    let now = Date()
    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建昨天日期"])
    }
    
    let isYesterday = calendar.isDateInYesterday(yesterday)
    print("   📅 昨天的日期: \(isYesterday)")
    
    try assertTrue(isYesterday, "应该识别为昨天")
}

runTest(name: "TC-035-4: 中文日期格式") {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日"
    
    let calendar = Calendar.current
    let components = DateComponents(year: 2026, month: 3, day: 10)
    guard let testDate = calendar.date(from: components) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建日期"])
    }
    
    let result = formatter.string(from: testDate)
    print("   📅 中文日期: \(result)")
    
    try assertEqual(result, "3月10日", "中文日期格式")
}

// ============================================================
// TC-036: 字符串处理测试
// ============================================================

runTest(name: "TC-036-1: 空字符串") {
    let empty = ""
    try assertTrue(empty.isEmpty, "应该识别为空")
    try assertEqual(empty.count, 0, "长度应为 0")
}

runTest(name: "TC-036-2: 长字符串（500字符）") {
    let longText = String(repeating: "测试", count: 250)
    print("   📝 字符串长度: \(longText.count)")
    
    try assertEqual(longText.count, 500, "应该是 500 字符")
}

runTest(name: "TC-036-3: 特殊字符处理") {
    let special = "测试 😀🎉🚀 @#$%^&*() \n换行\t制表符"
    print("   📝 特殊字符: \(special)")
    print("   📝 长度: \(special.count)")
    
    try assertTrue(special.contains("😀"), "应该包含 Emoji")
    try assertTrue(special.contains("\n"), "应该包含换行符")
    try assertTrue(special.contains("\t"), "应该包含制表符")
}

runTest(name: "TC-036-4: 字符串截断（模拟 500 字限制）") {
    let longText = String(repeating: "测试", count: 300) // 600 字符
    let maxLength = 500
    
    let truncated = String(longText.prefix(maxLength))
    print("   📝 原始长度: \(longText.count)")
    print("   📝 截断后: \(truncated.count)")
    
    try assertEqual(truncated.count, maxLength, "应该截断到 500")
}

// ============================================================
// TC-037: 性能测试
// ============================================================

runTest(name: "TC-037-1: 图片压缩性能") {
    let size = CGSize(width: 4000, height: 3000)
    let renderer = UIGraphicsImageRenderer(size: size)
    let testImage = renderer.image { context in
        UIColor.purple.setFill()
        context.fill(CGRect(origin: .zero, size: size))
    }
    
    let startTime = Date()
    _ = testImage.jpegData(compressionQuality: 0.6)
    let duration = Date().timeIntervalSince(startTime)
    
    print("   ⏱️  压缩耗时: \(String(format: "%.3f", duration)) 秒")
    
    try assertLessThan(duration, 2.0, "压缩应该在 2 秒内完成")
}

// ============================================================
// 测试总结
// ============================================================

print("\n" + String(repeating: "=", count: 60))
print("📊 测试总结")
print(String(repeating: "=", count: 60))
print("总测试数: \(totalTests)")
print("✅ 通过: \(passedTests)")
print("❌ 失败: \(failedTests)")
print("通过率: \(String(format: "%.1f", Double(passedTests) / Double(totalTests) * 100))%")
print(String(repeating: "=", count: 60))

if failedTests == 0 {
    print("\n🎉 所有测试通过！")
    exit(0)
} else {
    print("\n⚠️  有 \(failedTests) 个测试失败")
    exit(1)
}

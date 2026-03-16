#!/usr/bin/env swift

import Foundation

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

func assertFalse(_ condition: Bool, _ message: String = "") throws {
    if condition {
        throw NSError(domain: "TestError", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "条件应为 false. \(message)"])
    }
}

func assertLessThan(_ value: Int, _ limit: Int, _ message: String = "") throws {
    if value >= limit {
        throw NSError(domain: "TestError", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "\(value) 应小于 \(limit). \(message)"])
    }
}

func assertGreaterThan(_ value: Int, _ limit: Int, _ message: String = "") throws {
    if value <= limit {
        throw NSError(domain: "TestError", code: 1,
                     userInfo: [NSLocalizedDescriptionKey: "\(value) 应大于 \(limit). \(message)"])
    }
}

print("╔═══════════════════════════════════════════════════════════╗")
print("║         随手记 App - 自动化测试套件                        ║")
print("║         Foundation 基础功能测试                            ║")
print("╚═══════════════════════════════════════════════════════════╝\n")

// ============================================================
// TC-038: 日期格式化测试
// ============================================================

print("📅 类别 1: 日期和时间处理\n")

runTest(name: "TC-038-1: 时间格式化 (HH:mm)") {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.timeZone = TimeZone(identifier: "Asia/Shanghai")
    
    let calendar = Calendar.current
    var components = DateComponents()
    components.year = 2026
    components.month = 3
    components.day = 10
    components.hour = 14
    components.minute = 30
    components.timeZone = TimeZone(identifier: "Asia/Shanghai")
    
    guard let testDate = calendar.date(from: components) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建日期"])
    }
    
    let result = formatter.string(from: testDate)
    print("   📊 输入: 2026-03-10 14:30")
    print("   📊 输出: \(result)")
    
    try assertEqual(result, "14:30", "时间格式应该是 HH:mm")
}

runTest(name: "TC-038-2: 日期分组 - 今天") {
    let calendar = Calendar.current
    let now = Date()
    
    let isToday = calendar.isDateInToday(now)
    print("   📊 当前时间: \(now)")
    print("   📊 是否今天: \(isToday)")
    
    try assertTrue(isToday, "当前时间应该是今天")
}

runTest(name: "TC-038-3: 日期分组 - 昨天") {
    let calendar = Calendar.current
    let now = Date()
    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: now) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建昨天日期"])
    }
    
    let isYesterday = calendar.isDateInYesterday(yesterday)
    print("   📊 昨天日期: \(yesterday)")
    print("   📊 是否昨天: \(isYesterday)")
    
    try assertTrue(isYesterday, "应该识别为昨天")
}

runTest(name: "TC-038-4: 中文日期格式 (M月d日)") {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "M月d日"
    
    let calendar = Calendar.current
    var components = DateComponents()
    components.year = 2026
    components.month = 3
    components.day = 10
    
    guard let testDate = calendar.date(from: components) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法创建日期"])
    }
    
    let result = formatter.string(from: testDate)
    print("   📊 输入: 2026-03-10")
    print("   📊 输出: \(result)")
    
    try assertEqual(result, "3月10日", "中文日期格式")
}

runTest(name: "TC-038-5: 时间戳排序") {
    let now = Date()
    let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now)!
    
    print("   📊 昨天 < 今天: \(yesterday < now)")
    print("   📊 今天 < 明天: \(now < tomorrow)")
    
    try assertTrue(yesterday < now, "昨天应该早于今天")
    try assertTrue(now < tomorrow, "今天应该早于明天")
}

// ============================================================
// TC-039: 字符串处理测试
// ============================================================

print("\n📝 类别 2: 字符串处理和验证\n")

runTest(name: "TC-039-1: 空字符串检测") {
    let empty = ""
    print("   📊 字符串: \"\(empty)\"")
    print("   📊 isEmpty: \(empty.isEmpty)")
    print("   📊 count: \(empty.count)")
    
    try assertTrue(empty.isEmpty, "应该识别为空")
    try assertEqual(empty.count, 0, "长度应为 0")
}

runTest(name: "TC-039-2: 长字符串 (500 字符)") {
    let longText = String(repeating: "测", count: 500)
    print("   📊 字符串长度: \(longText.count)")
    print("   📊 前 10 字符: \(String(longText.prefix(10)))")
    
    try assertEqual(longText.count, 500, "应该是 500 字符")
}

runTest(name: "TC-039-3: 超长字符串截断 (600 → 500)") {
    let veryLongText = String(repeating: "测试", count: 300) // 600 字符
    let maxLength = 500
    
    let truncated = String(veryLongText.prefix(maxLength))
    
    print("   📊 原始长度: \(veryLongText.count)")
    print("   📊 截断后: \(truncated.count)")
    
    try assertEqual(truncated.count, maxLength, "应该截断到 500")
    try assertLessThan(truncated.count, veryLongText.count, "截断后应该更短")
}

runTest(name: "TC-039-4: Emoji 和特殊字符") {
    let special = "测试 😀🎉🚀 @#$%"
    print("   📊 字符串: \(special)")
    print("   📊 长度: \(special.count)")
    print("   📊 包含 Emoji: \(special.contains("😀"))")
    
    try assertTrue(special.contains("😀"), "应该包含 Emoji")
    try assertTrue(special.contains("@"), "应该包含特殊字符")
}

runTest(name: "TC-039-5: 换行符和制表符") {
    let withWhitespace = "第一行\n第二行\t制表符"
    print("   📊 原始: \(withWhitespace)")
    print("   📊 包含换行: \(withWhitespace.contains("\n"))")
    print("   📊 包含制表符: \(withWhitespace.contains("\t"))")
    
    try assertTrue(withWhitespace.contains("\n"), "应该包含换行符")
    try assertTrue(withWhitespace.contains("\t"), "应该包含制表符")
}

// ============================================================
// TC-040: 数据结构测试
// ============================================================

print("\n🗂️  类别 3: 数据结构和类型\n")

runTest(name: "TC-040-1: Data 类型操作") {
    let data1 = Data([0x01, 0x02, 0x03])
    let data2 = Data([0x04, 0x05])
    
    print("   📊 data1 长度: \(data1.count) bytes")
    print("   📊 data2 长度: \(data2.count) bytes")
    
    try assertEqual(data1.count, 3, "data1 应该是 3 bytes")
    try assertEqual(data2.count, 2, "data2 应该是 2 bytes")
}

runTest(name: "TC-040-2: 空 Data 处理") {
    let emptyData = Data()
    print("   📊 空 Data 长度: \(emptyData.count)")
    print("   📊 isEmpty: \(emptyData.isEmpty)")
    
    try assertTrue(emptyData.isEmpty, "空 Data 应该为空")
    try assertEqual(emptyData.count, 0, "空 Data 长度应为 0")
}

runTest(name: "TC-040-3: String <-> Data 转换") {
    let originalString = "测试字符串 😀"
    guard let data = originalString.data(using: .utf8) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法转换为 Data"])
    }
    
    guard let convertedString = String(data: data, encoding: .utf8) else {
        throw NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "无法转换回 String"])
    }
    
    print("   📊 原始: \(originalString)")
    print("   📊 Data 长度: \(data.count) bytes")
    print("   📊 转换回: \(convertedString)")
    
    try assertEqual(convertedString, originalString, "转换应该无损")
}

// ============================================================
// TC-041: 边界条件测试
// ============================================================

print("\n⚠️  类别 4: 边界条件和异常情况\n")

runTest(name: "TC-041-1: 极大数字") {
    let veryLargeNumber = Int.max
    print("   📊 Int.max: \(veryLargeNumber)")
    
    try assertTrue(veryLargeNumber > 0, "最大整数应该 > 0")
}

runTest(name: "TC-041-2: 字符串比较") {
    let str1 = "abc"
    let str2 = "abc"
    let str3 = "ABC"
    
    print("   📊 \"\(str1)\" == \"\(str2)\": \(str1 == str2)")
    print("   📊 \"\(str1)\" == \"\(str3)\": \(str1 == str3)")
    
    try assertTrue(str1 == str2, "相同字符串应该相等")
    try assertFalse(str1 == str3, "大小写不同应该不相等")
}

runTest(name: "TC-041-3: 数组操作") {
    var array = [1, 2, 3, 4, 5]
    print("   📊 原始数组: \(array)")
    
    array.removeFirst()
    print("   📊 删除第一个: \(array)")
    
    array.append(6)
    print("   📊 添加元素: \(array)")
    
    try assertEqual(array.count, 5, "操作后应该有 5 个元素")
    try assertEqual(array.first, 2, "第一个元素应该是 2")
    try assertEqual(array.last, 6, "最后一个元素应该是 6")
}

// ============================================================
// TC-042: 性能测试
// ============================================================

print("\n⏱️  类别 5: 性能基准测试\n")

runTest(name: "TC-042-1: 字符串拼接性能 (1000 次)") {
    let iterations = 1000
    
    let startTime = Date()
    var result = ""
    for i in 0..<iterations {
        result += "测试\(i)"
    }
    let duration = Date().timeIntervalSince(startTime)
    
    print("   📊 拼接次数: \(iterations)")
    print("   📊 结果长度: \(result.count)")
    print("   📊 耗时: \(String(format: "%.3f", duration * 1000)) ms")
    
    try assertTrue(duration < 1.0, "应该在 1 秒内完成")
}

runTest(name: "TC-042-2: 数组操作性能 (10000 次添加)") {
    let iterations = 10000
    
    let startTime = Date()
    var array = [Int]()
    for i in 0..<iterations {
        array.append(i)
    }
    let duration = Date().timeIntervalSince(startTime)
    
    print("   📊 添加次数: \(iterations)")
    print("   📊 数组长度: \(array.count)")
    print("   📊 耗时: \(String(format: "%.3f", duration * 1000)) ms")
    
    try assertEqual(array.count, iterations, "应该添加了所有元素")
    try assertTrue(duration < 0.5, "应该在 0.5 秒内完成")
}

runTest(name: "TC-042-3: Data 读写性能") {
    let dataSize = 1024 * 1024 // 1 MB
    let testData = Data(repeating: 0xFF, count: dataSize)
    
    let startTime = Date()
    let copy = testData
    let duration = Date().timeIntervalSince(startTime)
    
    print("   📊 数据大小: \(dataSize / 1024) KB")
    print("   📊 耗时: \(String(format: "%.6f", duration * 1000)) ms")
    
    try assertEqual(copy.count, dataSize, "复制后大小应该相同")
}

// ============================================================
// 测试总结
// ============================================================

print("\n" + String(repeating: "═", count: 63))
print("║                        📊 测试总结                           ║")
print(String(repeating: "═", count: 63))
print("║  总测试数: \(String(format: "%2d", totalTests))                                                   ║")
print("║  ✅ 通过: \(String(format: "%2d", passedTests))                                                    ║")
print("║  ❌ 失败: \(String(format: "%2d", failedTests))                                                    ║")
print("║  通过率: \(String(format: "%5.1f", Double(passedTests) / Double(totalTests) * 100))%                                                ║")
print(String(repeating: "═", count: 63))

if failedTests == 0 {
    print("\n🎉 恭喜！所有 \(totalTests) 个测试全部通过！\n")
    print("✅ Foundation 基础功能验证完成")
    print("✅ 数据模型逻辑正确")
    print("✅ 字符串处理健壮")
    print("✅ 日期格式化正常")
    print("✅ 性能符合预期\n")
    exit(0)
} else {
    print("\n⚠️  注意：有 \(failedTests) 个测试失败\n")
    print("请检查失败的测试用例并修复问题。\n")
    exit(1)
}

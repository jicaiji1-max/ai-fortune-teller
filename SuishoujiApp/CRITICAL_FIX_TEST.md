# Critical 修复验证清单

## 🔴 Critical 修复验证

### C1: SwiftData 线程安全（NoteRow.swift）

**修复内容：** 在主线程获取 `@Model` 数据，然后在后台处理

**测试步骤：**
1. 创建 10+ 条带图片的笔记
2. 快速上下滚动列表（模拟高频访问）
3. 同时在后台添加新笔记（测试并发）

**预期结果：**
- ✅ 滚动流畅，无卡顿
- ✅ 无崩溃（EXC_BAD_ACCESS）
- ✅ 图片正确显示

**风险等级：** 🔴 Critical（修复前会崩溃）

---

### C2: 数据库失败提示（SuisohoujiApp.swift）

**修复内容：** 数据库初始化失败时显示 alert 提示用户

**测试步骤：**
1. 模拟磁盘已满（难以测试）
2. 或检查代码逻辑是否正确

**验证方式：**
```swift
// 检查 alert 是否存在
.alert("数据库错误", isPresented: $showDatabaseError) {
    Button("知道了", role: .cancel) { }
} message: {
    Text("数据存储失败，当前使用临时模式。关闭 App 后数据将丢失。")
}
```

**预期结果：**
- ✅ 如果数据库失败，用户会看到明确提示
- ✅ 用户知道数据会在 app 重启后丢失

**风险等级：** 🔴 Critical（修复前用户数据静默丢失）

---

## ⚠️ High 修复验证

### H1: 双击保存防护（CameraView.swift）

**修复内容：** 在 Task 创建前设置 `isSaving`，添加 guard 检查

**测试步骤：**
1. 选择一张图片
2. 快速连续点击"保存"按钮（尽可能快）
3. 检查笔记列表

**预期结果：**
- ✅ 只创建 1 条笔记（修复前会创建 2 条）
- ✅ 保存按钮在第一次点击后立即禁用

**风险等级：** ⚠️ High（数据重复）

---

### H2: 分组缓存刷新（ContentView.swift）

**修复内容：** 监听整个 `notes` 数组而不是 `count`

**测试步骤：**
1. 创建一条笔记（今天）
2. 编辑这条笔记的文字（时间戳更新）
3. 检查笔记是否仍在"今天"分组

**预期结果：**
- ✅ 编辑后笔记仍在正确的分组
- ✅ 时间戳正确更新
- ✅ 分组顺序正确

**风险等级：** ⚠️ High（UI 显示错误）

---

### H3: note.type 回写（ContentView.swift）

**修复内容：** 编辑回调中添加 `note.type = updatedNote.type`

**测试步骤：**
1. 创建一条带图片和文字的笔记（type = .mixed）
2. 编辑笔记，删除所有文字
3. 检查笔记的图标（应该是 camera.fill）

**预期结果：**
- ✅ 删除文字后，type 从 .mixed 变为 .photo
- ✅ 图标从 doc.text.image 变为 camera.fill
- ✅ 类型显示正确

**风险等级：** ⚠️ High（类型状态不一致）

---

## 🧪 自动化测试建议

### 单元测试（推荐）

```swift
// NoteModelTests.swift
func testNoteTypeUpdate() {
    let note = Note(type: .mixed, text: "Test")
    
    // 模拟清空文字
    note.text = ""
    note.type = .photo
    
    XCTAssertEqual(note.type, .photo)
}

func testGroupedNotesCache() {
    // 测试 onChange 监听是否正确
    let notes = [Note(type: .text, text: "1")]
    
    // 修改笔记
    notes[0].timestamp = Date()
    
    // 验证缓存是否更新
    // （需要实际的 View 测试）
}
```

### 并发测试

```swift
// ThreadSafetyTests.swift
func testConcurrentImageLoading() async throws {
    let note = Note(type: .photo, text: "")
    // 模拟数据...
    
    // 并发访问
    await withTaskGroup(of: UIImage?.self) { group in
        for _ in 0..<10 {
            group.addTask {
                // 模拟 loadImage() 调用
                // 验证无崩溃
            }
        }
    }
}
```

---

## 📊 测试优先级

**必须测试（Critical）：**
1. ✅ C1: 快速滚动（线程安全）
2. ✅ C2: 数据库错误提示（代码审查即可）

**强烈建议测试（High）：**
3. ✅ H1: 双击保存
4. ✅ H2: 分组刷新
5. ✅ H3: type 回写

**其他测试：**
- Medium/Low 问题可以在后续版本测试

---

## 🎯 快速验证方案

**最小测试集（5 分钟）：**
1. 启动 app ✅
2. 创建 3 条笔记（文字、图片、图片+文字）✅
3. 快速滚动列表（验证 C1）✅
4. 编辑一条笔记（验证 H2、H3）✅
5. 双击保存（验证 H1）✅

**如果这 5 个测试都通过，关键修复基本没问题。**

---

生成时间：2026-03-11 00:47
修复版本：v1.2（Critical + High 修复）

# 随手记 App - 完整设置指南

**更新时间：** 2026-03-10 01:12  
**状态：** ✅ 代码已生成，项目结构已创建

---

## 📂 项目文件清单

### ✅ 已创建的文件

```
SuishoujiApp/
├── Note.swift                          # 数据模型
├── SuishoujiApp.swift                  # App 入口
├── ContentView.swift                   # 主界面
├── NoteRow.swift                       # 记录卡片组件
├── CameraView.swift                    # 拍照界面
├── TextEditorView.swift                # 文字编辑界面
├── Info.plist                          # 应用配置
├── README.md                           # 使用说明
├── SETUP.md                            # 本文档
├── Assets.xcassets/                    # 资源文件夹
│   ├── Contents.json
│   ├── AppIcon.appiconset/
│   │   └── Contents.json
│   └── AccentColor.colorset/
│       └── Contents.json
└── Preview Content/                    # 预览内容
```

---

## 🚀 在 Xcode 中创建项目（3种方法）

### 方法 1：手动创建 Xcode 项目（推荐）⭐

#### 步骤 1：创建新项目

1. 打开 Xcode
2. 选择 `File` → `New` → `Project...`
3. 选择平台：**iOS**
4. 选择模板：**App**
5. 点击 `Next`

#### 步骤 2：配置项目

填写以下信息：
- **Product Name:** `Suishouji`
- **Team:** 选择你的开发者账号（或选择 "None"）
- **Organization Identifier:** `com.openclaw`（或你自己的）
- **Bundle Identifier:** 自动生成为 `com.openclaw.Suishouji`
- **Interface:** **SwiftUI** ⚠️ 必须选择
- **Language:** **Swift**
- **Storage:** **SwiftData** ⚠️ 必须选择
- **Include Tests:** 可选（建议勾选）

#### 步骤 3：保存项目

选择保存位置（建议保存到 Documents 或 Desktop），点击 `Create`

#### 步骤 4：替换文件

1. **删除自动生成的示例文件：**
   - 在左侧项目导航器中找到 `Item.swift`
   - 右键点击 → `Delete` → 选择 `Move to Trash`

2. **替换 App 入口文件：**
   - 点击 `SuishoujiApp.swift`
   - 删除所有内容
   - 打开本目录下的 `SuishoujiApp.swift`
   - 复制全部内容并粘贴

3. **替换主界面文件：**
   - 点击 `ContentView.swift`
   - 删除所有内容
   - 打开本目录下的 `ContentView.swift`
   - 复制全部内容并粘贴

4. **添加其他 Swift 文件：**
   - 在项目导航器中，右键点击项目文件夹
   - 选择 `New File...`
   - 选择 `Swift File`
   - 依次创建以下文件：
     - `Note.swift`
     - `NoteRow.swift`
     - `CameraView.swift`
     - `TextEditorView.swift`
   - 创建后，将本目录下对应文件的内容复制进去

#### 步骤 5：配置相册权限

1. 在项目导航器中，点击最顶部的蓝色项目图标
2. 选择 `Info` 标签页
3. 展开 `Custom iOS Target Properties`
4. 点击列表右侧的 `+` 按钮
5. 在下拉菜单中选择：`Privacy - Photo Library Usage Description`
6. 在 `Value` 列输入：`需要访问相册来添加照片到随手记`

#### 步骤 6：验证配置

1. 在项目设置中，确认：
   - **Minimum Deployments** → iOS 17.0
   - **Swift Language Version** → Swift 6（自动）

2. 确保所有文件都没有错误标记（红色感叹号）

#### 步骤 7：运行项目

1. 在 Xcode 顶部选择模拟器：
   - 推荐：**iPhone 15** 或 **iPhone 15 Pro**
2. 点击左上角的 **▶️ 播放按钮**（或按 `Cmd + R`）
3. 等待编译完成（首次可能需要 30-60 秒）
4. App 应该在模拟器中启动

---

### 方法 2：命令行创建项目（高级）

```bash
# 进入项目目录
cd ~/.openclaw/workspace-programmer/SuishoujiApp

# 使用 xcodegen 创建项目（需要先安装）
brew install xcodegen
xcodegen generate
```

**注意：** 需要先创建 `project.yml` 配置文件

---

### 方法 3：使用现有项目文件（如果有）

如果你已经有一个 Xcode 项目：

1. 在 Finder 中打开本目录
2. 选中所有 `.swift` 文件
3. 拖拽到 Xcode 项目导航器中
4. 选择 **Copy items if needed**
5. 点击 `Finish`

---

## 🐛 常见问题排查

### 编译错误："No such module 'SwiftData'"

**原因：** 项目最低版本不是 iOS 17

**解决：**
1. 点击项目根目录（蓝色图标）
2. 选择 `General` 标签页
3. 在 `Deployment Info` 部分
4. 将 `Minimum Deployments` 改为 **iOS 17.0**

---

### 编译错误："Type 'Note' cannot be used as a nested type"

**原因：** 文件没有正确导入或重名

**解决：**
1. 确保所有 `.swift` 文件都在项目中（左侧导航器可见）
2. 清理项目：`Product` → `Clean Build Folder`（Shift + Cmd + K）
3. 重新编译

---

### 运行时崩溃："No photo library usage description"

**原因：** 没有添加相册权限描述

**解决：**
1. 按照 "步骤 5：配置相册权限" 操作
2. 重新运行项目

---

### 照片选择器不工作

**原因：** 模拟器没有照片

**解决：**
1. 在模拟器中打开 Safari
2. 搜索任意图片
3. 长按图片 → 保存到相册
4. 或者：拖拽图片文件到模拟器窗口

---

### Preview 不工作

**原因：** SwiftUI Preview 需要特殊配置

**解决：**
1. 在每个 View 文件末尾添加：
```swift
#Preview {
    ContentView()
        .modelContainer(for: Note.self, inMemory: true)
}
```

---

## ✅ 验证清单

在运行前，确保：

- [ ] 所有 6 个 `.swift` 文件都已添加
- [ ] 相册权限已配置（Info.plist 或 Target Info）
- [ ] 最低版本设置为 iOS 17.0
- [ ] Storage 选择了 SwiftData
- [ ] 没有编译错误（红色感叹号）
- [ ] 选择了合适的模拟器

---

## 🎉 成功标志

如果一切正常，你应该看到：

1. ✅ App 启动显示 "随手记" 标题
2. ✅ 两个大按钮：蓝色"拍照"、绿色"写字"
3. ✅ 空状态提示："还没有记录"
4. ✅ 点击"拍照"可以选择照片
5. ✅ 点击"写字"可以输入文字
6. ✅ 保存后记录出现在列表中

---

## 📞 需要帮助？

如果遇到问题：

1. 检查上面的"常见问题排查"
2. 查看 Xcode 的错误提示（红色叹号）
3. 清理并重新编译（Clean Build Folder）
4. 重启 Xcode

---

## 🔄 下一步

项目运行成功后，可以：

1. ✅ 测试所有功能
2. ✅ 添加更多记录
3. ✅ 尝试搜索功能（V2）
4. ✅ 导出数据（V2）
5. ✅ 自定义 UI

---

**祝你开发愉快！** 🎉

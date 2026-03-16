# 随手记 App - draw.io 架构图说明

**创建日期：** 2026-03-13  
**文件数量：** 3 个 draw.io 文件

---

## 📁 文件列表

### 1. SuishoujiApp_Architecture.drawio
**应用架构流程图** - 展示整体架构和组件关系

**包含内容：**
- App 入口 (SuishoujiApp.swift)
- ModelContainer (SwiftData)
- ContentView (主界面)
- UI 组件层 (ActionButton, NoteRow)
- Sheet 视图层 (CameraView, TextEditorView)
- 删除功能 (3 种方式)
- 数据模型层 (Note, NoteType)
- 数据流向 (创建、保存、删除、编辑)

**适合场景：**
- 了解整体架构
- 新人入职培训
- 技术文档编写

---

### 2. SuishoujiApp_Flow.drawio
**用户交互流程图** - 展示用户使用流程

**包含内容：**
- 开始 → 主界面
- 用户操作决策（拍照/写字/查看）
- CameraView / TextEditorView 流程
- 保存操作
- 笔记列表展示
- 删除功能流程（3 种方式）
- 确认对话框
- 删除执行
- 返回列表

**适合场景：**
- 用户体验分析
- 交互设计评审
- 测试用例编写

---

### 3. SuishoujiApp_TestArchitecture.drawio
**测试架构图** - 展示测试金字塔和覆盖范围

**包含内容：**
- 测试金字塔（E2E → 集成 → 单元）
- 8 个测试文件详情
- 测试覆盖范围（7 大类）
- 运行命令
- 输出示例

**测试统计：**
- E2E 测试：22 个
- 集成测试：42 个
- 单元测试：185 个
- 手动用例自动化：25 个
- **总计：252 个测试，100% 通过**

**适合场景：**
- 测试报告
- 质量保障文档
- 代码审查

---

## 🎨 颜色说明

| 颜色 | 含义 | 示例 |
|------|------|------|
| 🔵 蓝色 | App 入口/数据模型 | SuishoujiApp, Note |
| 🟢 绿色 | UI 组件/主界面 | ContentView, ActionButton |
| 🔴 红色 | Sheet 视图/删除操作 | CameraView, 删除按钮 |
| 🟡 黄色 | 数据操作/决策 | 保存，用户决策 |
| 🟣 紫色 | 列表/组件 | NoteRow, 测试文件 |
| 🟠 橙色 | 删除功能 | 三种删除方式 |

---

## 📊 架构图概览

```
┌─────────────────────────────────────────┐
│         SuishoujiApp (入口)             │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│      ModelContainer (SwiftData)         │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│        ContentView (主界面)             │
└──┬──────┬────────────────┬──────────────┘
   │      │                │
   ▼      ▼                ▼
拍照   写字            笔记列表
按钮   按钮           (NoteRow)
   │      │                │
   ▼      ▼                ▼
Camera TextEditor      删除功能
 View     View        (3 种方式)
   │      │                │
   └──┬───┘                ▼
      │            确认对话框
      ▼                    │
   保存 ──────────────────┘
      │
      ▼
SwiftData 持久化
```

---

## 🚀 如何使用

### 1. 打开 draw.io 文件

**方法 A：在线打开**
1. 访问 https://app.diagrams.net/
2. 选择 `File` → `Open From` → `Device...`
3. 选择对应的 `.drawio` 文件

**方法 B：桌面应用**
1. 下载 draw.io Desktop
2. 直接双击 `.drawio` 文件

**方法 C：VS Code**
1. 安装 "Draw.io Integration" 插件
2. 直接在 VS Code 中打开编辑

---

### 2. 编辑和导出

**导出格式：**
- PNG / JPEG（图片）
- PDF（文档）
- SVG（矢量图）
- HTML（可交互）

**导出步骤：**
1. `File` → `Export as` → 选择格式
2. 设置分辨率（推荐 300 DPI）
3. 选择保存位置

---

## 📝 更新记录

| 日期 | 文件 | 更新内容 |
|------|------|----------|
| 2026-03-13 | Architecture.drawio | 创建应用架构图 |
| 2026-03-13 | Flow.drawio | 创建用户交互流程图 |
| 2026-03-13 | TestArchitecture.drawio | 创建测试架构图 |

---

## 🎯 使用建议

### 技术文档
- 使用 **Architecture.drawio** 展示整体架构
- 使用 **Flow.drawio** 展示用户流程
- 使用 **TestArchitecture.drawio** 展示测试覆盖

### 代码审查
- 展示 **Architecture.drawio** 说明组件关系
- 展示 **TestArchitecture.drawio** 说明测试完整性

### 新人培训
- 按顺序展示三个图：架构 → 流程 → 测试
- 配合代码讲解效果更好

---

## 📞 相关文件

- `TEST_REPORT_COMPLETE.md` - 完整测试报告
- `TEST_CASES.md` - 测试用例文档
- `run_all_tests.sh` - 自动化测试脚本
- `SuishoujiTests/` - 测试代码目录

---

**draw.io 文件位置：**
```
~/.openclaw/workspace-programmer/SuishoujiApp/
├── SuishoujiApp_Architecture.drawio
├── SuishoujiApp_Flow.drawio
└── SuishoujiApp_TestArchitecture.drawio
```

**用 draw.io 打开即可查看！** 🎉

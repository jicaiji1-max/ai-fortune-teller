# 随手记 - 完整设计规范

**版本：** v1.0  
**更新时间：** 2026-03-10  
**适配平台：** iOS 17+  
**设计风格：** iOS Native Design

---

## 📋 目录

1. [设计系统](#设计系统)
2. [界面设计](#界面设计)
3. [组件库](#组件库)
4. [交互设计](#交互设计)
5. [响应式设计](#响应式设计)
6. [深色模式](#深色模式)
7. [可访问性](#可访问性)

---

## 🎨 设计系统

### 配色方案

#### 主色调
```
蓝色（拍照按钮）  #007AFF   RGB(0, 122, 255)
绿色（写字按钮）  #34C759   RGB(52, 199, 89)
```

#### 辅助色
```
背景色         #F2F2F7   RGB(242, 242, 247)
卡片背景       #FFFFFF   RGB(255, 255, 255)
分隔线         #E5E5EA   RGB(229, 229, 234)
```

#### 文字颜色
```
主文字         #000000   RGB(0, 0, 0)      - 标题、正文
次要文字       #8E8E93   RGB(142, 142, 147) - 说明文字
三级文字       #C7C7CC   RGB(199, 199, 204) - 时间戳
```

#### 系统颜色
```
成功色         #34C759   RGB(52, 199, 89)
警告色         #FF9500   RGB(255, 149, 0)
错误色         #FF3B30   RGB(255, 59, 48)
```

### 字体规范

#### 字体家族
```
SF Pro Display   - 标题、大号文字
SF Pro Text      - 正文、小号文字
SF Mono          - 代码、等宽字体（可选）
```

#### 字体大小
```
超大标题   34pt   SF Pro Display Bold
大标题     28pt   SF Pro Display Bold
中标题     22pt   SF Pro Display Semibold
小标题     20pt   SF Pro Display Semibold
按钮文字   17pt   SF Pro Text Semibold
正文       16pt   SF Pro Text Regular
说明文字   14pt   SF Pro Text Regular
时间戳     13pt   SF Pro Text Medium
标签       11pt   SF Pro Text Medium
```

#### 行高
```
标题       1.2 倍字号
正文       1.4 倍字号
说明文字   1.3 倍字号
```

### 间距系统

#### 标准间距（8pt 网格系统）
```
超小间距   4pt
小间距     8pt
中间距     16pt
大间距     24pt
超大间距   32pt
巨大间距   48pt
```

#### 常用间距组合
```
卡片内边距     16pt
卡片间距       8pt
按钮高度       56pt（大）/ 44pt（中）/ 32pt（小）
列表行高       44pt（最小点击区域）
```

### 圆角规范

```
超小圆角   4pt   - 标签、徽章
小圆角     8pt   - 图片、缩略图
中圆角     12pt  - 按钮
大圆角     16pt  - 卡片
超大圆角   24pt  - 模态窗口、底部抽屉
```

### 阴影规范

#### 卡片阴影
```css
/* 小阴影 - 卡片 */
box-shadow: 0 1px 4px rgba(0, 0, 0, 0.05);

/* 中阴影 - 浮动元素 */
box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);

/* 大阴影 - 模态窗口 */
box-shadow: 0 4px 16px rgba(0, 0, 0, 0.15);
```

#### 按钮阴影
```css
/* 常规按钮 */
box-shadow: 0 2px 8px rgba(0, 122, 255, 0.3);

/* 按下状态 */
box-shadow: 0 1px 4px rgba(0, 122, 255, 0.2);
```

---

## 📱 界面设计

### 1. 主界面（Home Screen）

#### 布局结构
```
┌─────────────────────────────────────┐
│ 导航栏 (44pt)                       │
├─────────────────────────────────────┤
│ 顶部间距 (24pt)                     │
│                                     │
│ ┌───────────┐ ┌───────────┐        │
│ │ 拍照按钮  │ │ 写字按钮  │        │ 大按钮区
│ │ (120pt)   │ │ (120pt)   │        │
│ └───────────┘ └───────────┘        │
│                                     │
│ 分隔线 (1pt) [16pt margins]        │
│                                     │
│ 日期标题 "今天 (3)" [20pt]         │
│                                     │
│ ┌───────────────────────────────┐  │
│ │ 记录卡片 1                     │  │
│ └───────────────────────────────┘  │
│ ┌───────────────────────────────┐  │
│ │ 记录卡片 2                     │  │ 记录列表
│ └───────────────────────────────┘  │
│ ┌───────────────────────────────┐  │
│ │ 记录卡片 3                     │  │
│ └───────────────────────────────┘  │
│                                     │
│ 日期标题 "昨天 (2)"                 │
│ ...                                 │
└─────────────────────────────────────┘
```

#### 导航栏
```
高度: 44pt
背景色: #FFFFFF
底部边框: 1pt #E5E5EA

左侧元素:
  - 汉堡菜单图标 (24×24pt, #000000)
  - 间距: 16pt from left
  
标题:
  - 文字: "随手记"
  - 字体: 28pt SF Pro Display Bold
  - 颜色: #000000
  - 位置: 左侧，距菜单图标 12pt
  
右侧元素:
  - 设置图标 (24×24pt, #000000)
  - 间距: 16pt from right
```

#### 大按钮
```
尺寸:
  - 宽度: (屏幕宽度 - 44pt) / 2
  - 高度: 120pt
  - 间距: 左右 16pt, 按钮间距 12pt

拍照按钮:
  - 背景色: #007AFF
  - 圆角: 12pt
  - 阴影: 0 2px 8px rgba(0, 122, 255, 0.3)
  - 图标: camera.fill (SF Symbol, 36pt, 白色)
  - 文字: "拍照" (17pt Semibold, 白色)
  - 布局: 垂直居中，图标在上，文字在下，间距 8pt

写字按钮:
  - 背景色: #34C759
  - 其他同上，图标改为 pencil (SF Symbol)
```

#### 记录卡片
```
尺寸:
  - 宽度: 屏幕宽度 - 32pt (左右各 16pt margin)
  - 高度: 自适应
  - 圆角: 16pt
  - 内边距: 16pt
  - 卡片间距: 8pt

背景色: #FFFFFF
阴影: 0 1px 4px rgba(0, 0, 0, 0.05)

内容布局:
  ┌────────────────────────────────┐
  │ [emoji] 标题            时间    │  ← 顶部行
  │ [照片缩略图（如果有）]          │  ← 照片区
  │ 文字内容（最多3行）             │  ← 文字区
  └────────────────────────────────┘

Emoji:
  - 尺寸: 24×24pt
  - 位置: 左上角
  
标题:
  - 字体: 16pt SF Pro Text Semibold
  - 颜色: #000000
  - 最大行数: 1
  
时间:
  - 字体: 13pt SF Pro Text Medium
  - 颜色: #8E8E93
  - 位置: 右上角
  
照片（如果有）:
  - 宽度: 卡片宽度 - 32pt
  - 高度: 200pt（固定）
  - 圆角: 8pt
  - 间距: 上方 12pt
  - object-fit: cover
  
文字内容:
  - 字体: 16pt SF Pro Text Regular
  - 颜色: #000000
  - 行高: 22pt
  - 最大行数: 3
  - 超出显示: "..."
```

### 2. 拍照界面（Camera View）

#### 布局结构
```
┌─────────────────────────────────────┐
│ 顶部栏 (44pt)                       │
│ [取消]         拍照         [保存]  │
├─────────────────────────────────────┤
│ 顶部间距 (24pt)                     │
│                                     │
│ ┌───────────────────────────────┐  │
│ │                               │  │
│ │      照片预览区               │  │
│ │      (280pt 高度)             │  │
│ │                               │  │
│ └───────────────────────────────┘  │
│                                     │
│ 间距 (24pt)                         │
│                                     │
│ 标签: "添加说明（可选）"            │
│ ┌───────────────────────────────┐  │
│ │ 文字输入框                     │  │
│ │ (100pt 高度)                   │  │
│ └───────────────────────────────┘  │
│                                     │
│ [剩余空间]                          │
│                                     │
│ ┌───────────────────────────────┐  │
│ │      保存按钮 (56pt)          │  │  ← 底部固定
│ └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

#### 顶部栏
```
高度: 44pt
背景色: #FFFFFF
底部边框: 1pt #E5E5EA

取消按钮:
  - 文字: "取消" (17pt, #007AFF)
  - 位置: 左侧 16pt
  
标题:
  - 文字: "拍照" (17pt Semibold, #000000)
  - 位置: 居中
  
保存按钮:
  - 文字: "保存" (17pt Semibold)
  - 颜色: 
    - 有照片: #007AFF
    - 无照片: #C7C7CC (禁用)
  - 位置: 右侧 16pt
```

#### 照片预览区
```
尺寸:
  - 宽度: 屏幕宽度 - 32pt
  - 高度: 280pt
  - 圆角: 16pt
  - margin: 左右 16pt

未选择状态:
  - 背景色: #F2F2F7
  - 高度: 200pt
  - 内容: camera.fill 图标 (40pt, #007AFF)
          + "点击选择照片" (14pt, #8E8E93)
  - 布局: 垂直居中

已选择状态:
  - 显示照片预览
  - object-fit: cover
  - 右下角: 编辑图标 (pencil.circle.fill, 24pt)
            背景: 白色半透明 (rgba(255,255,255,0.9))
            圆形背景直径: 40pt
```

#### 文字输入框
```
尺寸:
  - 宽度: 屏幕宽度 - 32pt
  - 最小高度: 100pt
  - 最大高度: 200pt (自适应)
  - 圆角: 12pt
  - 边框: 1pt #E5E5EA

背景色: #FFFFFF
内边距: 12pt
占位符: "输入文字..." (#C7C7CC)
字体: 16pt SF Pro Text Regular
行高: 22pt
```

#### 保存按钮
```
尺寸:
  - 宽度: 屏幕宽度 - 32pt
  - 高度: 56pt
  - 圆角: 12pt
  - 位置: 底部安全区上方 16pt

启用状态:
  - 背景色: #007AFF
  - 文字: "保存" (17pt Semibold, 白色)
  - 阴影: 0 2px 8px rgba(0, 122, 255, 0.3)

禁用状态:
  - 背景色: #E5E5EA
  - 文字: "保存" (17pt Semibold, #C7C7CC)
```

### 3. 文字编辑界面（Text Editor View）

#### 布局结构
```
┌─────────────────────────────────────┐
│ 顶部栏 (44pt)                       │
│ [取消]         写字         [保存]  │
├─────────────────────────────────────┤
│ 顶部间距 (16pt)                     │
│                                     │
│ ┌───────────────────────────────┐  │
│ │                               │  │
│ │      大文本输入框             │  │
│ │      (填满剩余空间)            │  │
│ │                               │  │
│ │                               │  │
│ │                               │  │
│ └───────────────────────────────┘  │
│                                     │
│ ┌───────────────────────────────┐  │
│ │      保存按钮 (56pt)          │  │  ← 底部固定
│ └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

#### 文本输入框
```
尺寸:
  - 宽度: 屏幕宽度 - 32pt
  - 高度: 填满剩余空间（除去顶部栏和保存按钮）
  - 圆角: 12pt
  - 边框: 1pt #E5E5EA

背景色: #FFFFFF
内边距: 16pt
占位符: "输入文字..." (#C7C7CC)
字体: 16pt SF Pro Text Regular
行高: 24pt（比卡片中更宽松）

自动行为:
  - 进入界面自动聚焦
  - 键盘自动弹出
  - 支持多行输入
```

#### 键盘工具栏
```
高度: 44pt
背景色: #F2F2F7
顶部边框: 1pt #E5E5EA

完成按钮:
  - 文字: "完成" (17pt Semibold, #007AFF)
  - 背景色: #FFFFFF
  - 圆角: 8pt
  - 内边距: 8pt 16pt
  - 位置: 右侧 16pt
  - 作用: 收起键盘
```

---

## 🧩 组件库

### 按钮组件

#### 主要按钮（Primary Button）
```swift
struct PrimaryButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 4, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// 使用
PrimaryButton(
    title: "拍照",
    icon: "camera.fill",
    color: .blue,
    action: { /* ... */ }
)
```

#### 辅助按钮（Secondary Button）
```swift
struct SecondaryButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .foregroundColor(.white)
                .background(isEnabled ? Color.blue : Color.gray.opacity(0.3))
                .cornerRadius(12)
        }
        .disabled(!isEnabled)
    }
}
```

### 卡片组件

#### 记录卡片（Note Card）
```swift
struct NoteCard: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部行
            HStack {
                Text(note.emoji)
                    .font(.system(size: 24))
                if let title = note.title {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .lineLimit(1)
                }
                Spacer()
                Text(note.timeString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // 照片
            if let photoData = note.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(8)
            }
            
            // 文字内容
            if !note.text.isEmpty {
                Text(note.text)
                    .font(.system(size: 16))
                    .lineLimit(3)
            }
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
    }
}
```

### 输入组件

#### 文本输入框（Text Field）
```swift
struct NoteTextField: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat
    
    var body: some View {
        TextEditor(text: $text)
            .frame(minHeight: minHeight)
            .padding(12)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .overlay(
                Text(placeholder)
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(16)
                    .opacity(text.isEmpty ? 1 : 0),
                alignment: .topLeading
            )
    }
}
```

---

## 🎬 交互设计

### 动画效果

#### 按钮点击动画
```swift
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
```

#### 卡片展开/收起
```swift
withAnimation(.easeInOut(duration: 0.3)) {
    isExpanded.toggle()
}
```

#### 页面切换
```swift
// 使用 NavigationLink 的默认动画
// 持续时间: 0.35s
// 曲线: easeInOut
```

#### 删除操作
```swift
.swipeActions(edge: .trailing) {
    Button(role: .destructive) {
        withAnimation {
            modelContext.delete(note)
        }
    } label: {
        Label("删除", systemImage: "trash")
    }
}
```

### 手势交互

#### 卡片手势
```
点击: 查看详情
左滑: 显示删除按钮
长按: 快速菜单（编辑/删除/分享）
```

#### 照片手势
```
点击: 全屏查看
双指缩放: 放大/缩小
双击: 自动缩放（100% ↔ 原始尺寸）
```

---

## 📐 响应式设计

### iPhone 尺寸适配

#### 小屏（iPhone SE，320×568）
```
按钮高度: 100pt
照片高度: 180pt
字体缩小: -2pt
```

#### 标准屏（iPhone 15，390×844）
```
按钮高度: 120pt
照片高度: 200pt
字体: 标准
```

#### 大屏（iPhone 15 Pro Max，430×932）
```
按钮高度: 140pt
照片高度: 220pt
字体: 标准
```

### 横屏模式

#### 主界面
```
布局: 两列
左侧: 按钮 + 日期标题
右侧: 记录列表
```

#### 详情页
```
布局: 左右分栏
左侧: 照片（如果有）
右侧: 标题 + 文字内容
```

---

## 🌓 深色模式

### 配色调整

#### 背景色
```
主背景:        #000000  (纯黑)
卡片背景:      #1C1C1E  (深灰)
分隔线:        #38383A  (中灰)
```

#### 文字颜色
```
主文字:        #FFFFFF  (白色)
次要文字:      #98989D  (浅灰)
三级文字:      #636366  (中灰)
```

#### 按钮颜色
```
蓝色按钮:      #0A84FF  (更亮的蓝)
绿色按钮:      #30D158  (更亮的绿)
```

### SwiftUI 实现
```swift
Color(.systemBackground)  // 自动适配深色模式
Color(.secondarySystemBackground)
Color(.label)
Color(.secondaryLabel)
```

---

## ♿ 可访问性

### 颜色对比度
```
所有文字与背景对比度 ≥ 4.5:1 (WCAG AA)
大号文字 (≥18pt) 对比度 ≥ 3:1
```

### 点击区域
```
所有可点击元素 ≥ 44×44pt
```

### VoiceOver 支持
```swift
Image(systemName: "camera.fill")
    .accessibilityLabel("拍照按钮")
    .accessibilityHint("点击选择照片")
```

### 动态字体
```swift
.font(.system(size: 16))
// 改为
.font(.body)  // 支持系统字体缩放
```

---

## 📏 设计检查清单

### 布局
- [ ] 所有间距使用 8pt 网格
- [ ] 文字不触碰屏幕边缘（最小 16pt margin）
- [ ] 内容宽度有最大限制
- [ ] 垂直节奏一致

### 字体
- [ ] 清晰的层级（最多 3-4 种大小）
- [ ] 正文每行 ≤ 75 字符
- [ ] 标题使用 Bold/Semibold
- [ ] 支持动态字体

### 颜色
- [ ] 对比度达标 (≥4.5:1)
- [ ] 配色方案限制在 3 种颜色内
- [ ] 主色调仅用于 CTA 和重要元素
- [ ] 深色模式适配

### 交互
- [ ] 所有按钮有 hover 状态
- [ ] 点击区域 ≥ 44×44pt
- [ ] 动画流畅 (60fps)
- [ ] 有加载状态反馈

### 图片
- [ ] 使用 .webp 格式（Web）/ 压缩 JPEG (iOS)
- [ ] 添加 lazy loading
- [ ] 设置 aspect-ratio
- [ ] 所有图片有 alt 文本

---

## 📖 设计参考

### Apple 官方资源
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [iOS Design Kit (Figma)](https://www.figma.com/community/file/768726574016795759)

### 设计工具
- Figma - UI 设计
- Sketch - UI 设计
- SF Symbols App - 图标查找
- ColorSlurp - 颜色拾取

---

**设计师：** OpenClaw AI  
**开发：** Claude Code  
**版本：** v1.0  
**更新时间：** 2026-03-10

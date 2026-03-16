# 随手记 - 组件库

**版本：** v1.0  
**更新时间：** 2026-03-10

---

## 📋 组件清单

1. [按钮组件](#按钮组件)
2. [卡片组件](#卡片组件)
3. [输入组件](#输入组件)
4. [导航组件](#导航组件)
5. [列表组件](#列表组件)
6. [状态组件](#状态组件)

---

## 🔘 按钮组件

### ActionButton - 大按钮
主界面的两个大按钮（拍照、写字）

```swift
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 36))
                    .fontWeight(.medium)
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .foregroundColor(.white)
            .background(color)
            .cornerRadius(12)
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}
```

**使用示例：**
```swift
ActionButton(
    title: "拍照",
    icon: "camera.fill",
    color: .blue,
    action: { showCamera = true }
)
```

**样式变体：**
```swift
// 拍照按钮
ActionButton(..., color: Color(hex: "#007AFF"))

// 写字按钮
ActionButton(..., color: Color(hex: "#34C759"))
```

---

### PrimaryButton - 主要按钮
用于保存等主要操作

```swift
struct PrimaryButton: View {
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
                .shadow(
                    color: isEnabled ? Color.blue.opacity(0.3) : .clear,
                    radius: 4,
                    y: 2
                )
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}
```

**使用示例：**
```swift
PrimaryButton(
    title: "保存",
    isEnabled: !text.isEmpty,
    action: saveNote
)
```

---

### TextButton - 文字按钮
用于取消、完成等辅助操作

```swift
struct TextButton: View {
    let title: String
    let color: Color
    let weight: Font.Weight
    let action: () -> Void
    
    init(
        title: String,
        color: Color = .blue,
        weight: Font.Weight = .regular,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.color = color
        self.weight = weight
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 17, weight: weight))
                .foregroundColor(color)
        }
    }
}
```

**使用示例：**
```swift
// 取消按钮
TextButton(
    title: "取消",
    action: { dismiss() }
)

// 保存按钮（强调）
TextButton(
    title: "保存",
    weight: .semibold,
    action: saveNote
)
```

---

## 🗂️ 卡片组件

### NoteCard - 记录卡片
显示单条记录

```swift
struct NoteCard: View {
    let note: Note
    
    // Static DateFormatter
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()
    
    private var timeString: String {
        NoteCard.timeFormatter.string(from: note.timestamp)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 顶部行：emoji + 标题 + 时间
            HStack(alignment: .top) {
                // Type icon
                Image(systemName: note.type == .photo ? "camera.fill" : "pencil")
                    .font(.system(size: 20))
                    .foregroundColor(note.type == .photo ? .blue : .green)
                
                VStack(alignment: .leading, spacing: 4) {
                    // 标题（可选）
                    if !note.text.isEmpty {
                        Text(note.text.prefix(50))
                            .font(.system(size: 16, weight: .semibold))
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                // 时间
                Text(timeString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            // 照片（如果有）
            if let photoData = note.photoData,
               let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .cornerRadius(8)
            }
            
            // 文字内容
            if !note.text.isEmpty {
                Text(note.text)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .lineSpacing(2)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
```

**使用示例：**
```swift
ForEach(notes) { note in
    NoteCard(note: note)
        .padding(.horizontal)
        .padding(.vertical, 4)
}
```

---

## ✏️ 输入组件

### NoteTextEditor - 文本编辑器
大文本输入框

```swift
struct NoteTextEditor: View {
    @Binding var text: String
    @FocusState var isFocused: Bool
    let placeholder: String
    let minHeight: CGFloat
    let maxHeight: CGFloat?
    
    init(
        text: Binding<String>,
        isFocused: FocusState<Bool>,
        placeholder: String = "输入文字...",
        minHeight: CGFloat = 100,
        maxHeight: CGFloat? = nil
    ) {
        self._text = text
        self._isFocused = isFocused
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // 占位符
            if text.isEmpty {
                Text(placeholder)
                    .font(.system(size: 16))
                    .foregroundColor(.gray.opacity(0.5))
                    .padding(.top, 12)
                    .padding(.leading, 16)
            }
            
            // 文本编辑器
            TextEditor(text: $text)
                .font(.system(size: 16))
                .focused($isFocused)
                .frame(minHeight: minHeight)
                .frame(maxHeight: maxHeight)
                .padding(12)
        }
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isFocused ? Color.blue : Color.gray.opacity(0.3),
                    lineWidth: isFocused ? 2 : 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}
```

**使用示例：**
```swift
@State private var text = ""
@FocusState private var isFocused: Bool

NoteTextEditor(
    text: $text,
    isFocused: $isFocused,
    minHeight: 100,
    maxHeight: 200
)
```

---

### CaptionField - 文字说明输入框
拍照界面的可选文字输入

```swift
struct CaptionField: View {
    @Binding var text: String
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            TextEditor(text: $text)
                .font(.system(size: 16))
                .frame(height: 100)
                .padding(12)
                .background(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        }
    }
}
```

---

## 🧭 导航组件

### NavigationBar - 导航栏
通用导航栏

```swift
struct NavigationBar: View {
    let title: String
    let leftAction: (() -> Void)?
    let leftLabel: String?
    let rightAction: (() -> Void)?
    let rightLabel: String?
    let rightIsEnabled: Bool
    
    init(
        title: String,
        leftAction: (() -> Void)? = nil,
        leftLabel: String? = "取消",
        rightAction: (() -> Void)? = nil,
        rightLabel: String? = "保存",
        rightIsEnabled: Bool = true
    ) {
        self.title = title
        self.leftAction = leftAction
        self.leftLabel = leftLabel
        self.rightAction = rightAction
        self.rightLabel = rightLabel
        self.rightIsEnabled = rightIsEnabled
    }
    
    var body: some View {
        HStack {
            // 左侧按钮
            if let leftAction = leftAction, let leftLabel = leftLabel {
                Button(action: leftAction) {
                    Text(leftLabel)
                        .font(.system(size: 17))
                        .foregroundColor(.blue)
                }
            } else {
                Spacer().frame(width: 60)
            }
            
            Spacer()
            
            // 标题
            Text(title)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
            
            // 右侧按钮
            if let rightAction = rightAction, let rightLabel = rightLabel {
                Button(action: rightAction) {
                    Text(rightLabel)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(rightIsEnabled ? .blue : .gray.opacity(0.5))
                }
                .disabled(!rightIsEnabled)
            } else {
                Spacer().frame(width: 60)
            }
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(Color(.systemBackground))
        .overlay(
            Divider(),
            alignment: .bottom
        )
    }
}
```

**使用示例：**
```swift
NavigationBar(
    title: "拍照",
    leftAction: { dismiss() },
    rightAction: savePhoto,
    rightIsEnabled: selectedPhoto != nil
)
```

---

## 📜 列表组件

### SectionHeader - 日期分组标题
记录列表的日期标题

```swift
struct SectionHeader: View {
    let title: String
    let count: Int
    @Binding var isExpanded: Bool
    
    var body: some View {
        Button(action: { isExpanded.toggle() }) {
            HStack {
                Text("\(title) (\(count))")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}
```

---

## 🎨 状态组件

### EmptyState - 空状态
没有记录时的提示

```swift
struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    
    init(
        icon: String = "note.text",
        title: String = "还没有记录",
        message: String = "点击上方按钮开始记录你的生活"
    ) {
        self.icon = icon
        self.title = title
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 64))
                .foregroundColor(.gray.opacity(0.3))
            
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
            
            Text(message)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 80)
    }
}
```

---

### LoadingView - 加载状态
显示加载指示器

```swift
struct LoadingView: View {
    let message: String
    
    init(message: String = "加载中...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground).opacity(0.9))
    }
}
```

---

## 🎭 按钮样式

### ScaleButtonStyle - 缩放动画
点击时缩小的按钮样式

```swift
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(
                .spring(response: 0.2, dampingFraction: 0.7),
                value: configuration.isPressed
            )
    }
}
```

**使用示例：**
```swift
Button(action: { ... }) {
    Text("按钮")
}
.buttonStyle(ScaleButtonStyle())
```

---

## 🎨 辅助扩展

### Color Extension - 十六进制颜色
```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

**使用示例：**
```swift
Color(hex: "#007AFF")  // iOS 蓝色
Color(hex: "#34C759")  // iOS 绿色
```

---

## 📐 布局辅助

### Safe Area Insets
```swift
extension View {
    func safeAreaPadding(_ edges: Edge.Set = .all, _ length: CGFloat = 16) -> some View {
        self.padding(edges, length)
    }
}
```

---

## 🎯 使用示例

### 完整的主界面
```swift
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.timestamp, order: .reverse) private var notes: [Note]
    
    @State private var showCamera = false
    @State private var showTextEditor = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // 大按钮
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "拍照",
                            icon: "camera.fill",
                            color: Color(hex: "#007AFF"),
                            action: { showCamera = true }
                        )
                        ActionButton(
                            title: "写字",
                            icon: "pencil",
                            color: Color(hex: "#34C759"),
                            action: { showTextEditor = true }
                        )
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // 记录列表
                    if notes.isEmpty {
                        EmptyState()
                    } else {
                        ForEach(groupedNotes, id: \.0) { date, sectionNotes in
                            VStack(spacing: 8) {
                                SectionHeader(
                                    title: date,
                                    count: sectionNotes.count,
                                    isExpanded: .constant(true)
                                )
                                
                                ForEach(sectionNotes) { note in
                                    NoteCard(note: note)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("随手记")
            .sheet(isPresented: $showCamera) {
                CameraView(onSave: saveNote)
            }
            .sheet(isPresented: $showTextEditor) {
                TextEditorView(onSave: saveNote)
            }
        }
    }
    
    private var groupedNotes: [(String, [Note])] {
        // 分组逻辑...
    }
    
    private func saveNote(_ note: Note) {
        modelContext.insert(note)
    }
}
```

---

**组件库完成！** ✅  
所有组件都可以直接复制使用。

**创建者：** OpenClaw AI + Claude Code  
**版本：** v1.0  
**更新时间：** 2026-03-10

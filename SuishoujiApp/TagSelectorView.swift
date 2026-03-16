import SwiftUI

/// 标签选择组件，嵌入新建/编辑页
struct TagSelectorView: View {
    @Binding var selectedTags: [String]
    @ObservedObject var tagStore = TagStore.shared

    @State private var showAddTag = false
    @State private var newTagName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("标签（可选）")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tagStore.allTags, id: \.self) { tag in
                        TagChip(
                            title: tag,
                            isSelected: selectedTags.contains(tag)
                        ) {
                            toggleTag(tag)
                        }
                    }

                    // ＋ 新建标签
                    Button(action: { showAddTag = true }) {
                        Text("＋")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(red: 0.55, green: 0.22, blue: 0.83))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(red: 0.55, green: 0.22, blue: 0.83), style: StrokeStyle(lineWidth: 1.5, dash: [4]))
                            )
                    }
                }
                .padding(.horizontal)
            }
        }
        .alert("新建标签", isPresented: $showAddTag) {
            TextField("标签名称", text: $newTagName)
            Button("取消", role: .cancel) { newTagName = "" }
            Button("创建") {
                if !newTagName.isEmpty {
                    tagStore.addTag(newTagName)
                    selectedTags.append(newTagName.trimmingCharacters(in: .whitespacesAndNewlines))
                    newTagName = ""
                }
            }
        } message: {
            Text("输入新标签名称")
        }
    }

    private func toggleTag(_ tag: String) {
        if let idx = selectedTags.firstIndex(of: tag) {
            selectedTags.remove(at: idx)
        } else {
            selectedTags.append(tag)
        }
    }
}

/// 单个标签胶囊
struct TagChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? .white : Color.primary.opacity(0.6))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background {
                    if isSelected {
                        Capsule()
                            .fill(LinearGradient(
                                colors: [Color(red: 0.20, green: 0.35, blue: 0.95), Color(red: 0.55, green: 0.18, blue: 0.90)],
                                startPoint: .leading, endPoint: .trailing
                            ))
                    } else {
                        Capsule()
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

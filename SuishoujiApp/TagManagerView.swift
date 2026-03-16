import SwiftUI

/// 标签管理页：查看、删除、创建标签
struct TagManagerView: View {
    @ObservedObject var tagStore = TagStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var showAddSheet = false
    @State private var showEditSheet = false
    @State private var editingTag = ""
    @State private var editingTagIndex = 0
    @State private var newTagName = ""
    @State private var selectedEmoji = "🏷️"

    let emojiOptions = ["🏷️", "⭐️", "📖", "🏃", "💡", "🎵", "🎨", "💪", "🌙", "☕️", "🐱", "🌺"]

    var body: some View {
        NavigationStack {
            List {
                Section("默认标签") {
                    ForEach(tagStore.defaultTags, id: \.self) { tag in
                        HStack {
                            Text(tag)
                            Spacer()
                            Text("默认")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("我的标签") {
                    if tagStore.customTags.isEmpty {
                        Text("还没有自建标签")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    } else {
                        ForEach(Array(tagStore.customTags.enumerated()), id: \.offset) { idx, tag in
                            HStack {
                                Text(tag)
                                Spacer()
                                Button(action: {
                                    editingTag = tag
                                    editingTagIndex = idx
                                    // 解析 emoji 和名称
                                    let parts = tag.split(separator: " ", maxSplits: 1)
                                    if parts.count == 2 {
                                        selectedEmoji = String(parts[0])
                                        newTagName = String(parts[1])
                                    } else {
                                        selectedEmoji = "🏷️"
                                        newTagName = tag
                                    }
                                    showEditSheet = true
                                }) {
                                    Image(systemName: "pencil")
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { tagStore.customTags.remove(at: $0) }
                        }
                    }
                }
            }
            .navigationTitle("管理标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("完成") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { showAddSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                addTagSheet
            }
            .sheet(isPresented: $showEditSheet) {
                editTagSheet
            }
        }
    }

    private var addTagSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Emoji 选择
                VStack(alignment: .leading, spacing: 10) {
                    Text("选择图标")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button(action: { selectedEmoji = emoji }) {
                                Text(emoji)
                                    .font(.system(size: 28))
                                    .frame(width: 48, height: 48)
                                    .background(
                                        selectedEmoji == emoji
                                        ? Color(red: 0.20, green: 0.35, blue: 0.88).opacity(0.15)
                                        : Color(.systemGray6),
                                        in: RoundedRectangle(cornerRadius: 10)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedEmoji == emoji ? Color(red: 0.20, green: 0.35, blue: 0.88) : Color.clear, lineWidth: 2)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                // 标签名称
                VStack(alignment: .leading, spacing: 8) {
                    Text("标签名称")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    HStack(spacing: 10) {
                        Text(selectedEmoji)
                            .font(.title2)
                        TextField("输入标签名称", text: $newTagName)
                            .font(.system(size: 16))
                    }
                    .padding(12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                // 预览
                if !newTagName.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("预览")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)

                        TagChip(title: "\(selectedEmoji) \(newTagName)", isSelected: true) {}
                            .padding(.horizontal)
                    }
                }

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("新建标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showAddSheet = false
                        newTagName = ""
                        selectedEmoji = "🏷️"
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("创建") {
                        let full = "\(selectedEmoji) \(newTagName.trimmingCharacters(in: .whitespacesAndNewlines))"
                        tagStore.addTag(full)
                        showAddSheet = false
                        newTagName = ""
                        selectedEmoji = "🏷️"
                    }
                    .fontWeight(.semibold)
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var editTagSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                // Emoji 选择
                VStack(alignment: .leading, spacing: 10) {
                    Text("选择图标").font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button(action: { selectedEmoji = emoji }) {
                                Text(emoji).font(.system(size: 28))
                                    .frame(width: 48, height: 48)
                                    .background(selectedEmoji == emoji
                                        ? Color(red: 0.20, green: 0.35, blue: 0.88).opacity(0.15)
                                        : Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedEmoji == emoji ? Color(red: 0.20, green: 0.35, blue: 0.88) : Color.clear, lineWidth: 2))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

                // 标签名称
                VStack(alignment: .leading, spacing: 8) {
                    Text("标签名称").font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
                    HStack(spacing: 10) {
                        Text(selectedEmoji).font(.title2)
                        TextField("输入标签名称", text: $newTagName).font(.system(size: 16))
                    }
                    .padding(12)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("编辑标签")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        showEditSheet = false
                        newTagName = ""
                        selectedEmoji = "🏷️"
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        let full = "\(selectedEmoji) \(newTagName.trimmingCharacters(in: .whitespacesAndNewlines))"
                        if editingTagIndex < tagStore.customTags.count {
                            tagStore.customTags[editingTagIndex] = full
                        }
                        showEditSheet = false
                        newTagName = ""
                        selectedEmoji = "🏷️"
                    }
                    .fontWeight(.semibold)
                    .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

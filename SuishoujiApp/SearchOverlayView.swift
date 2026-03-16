import SwiftUI

/// 全屏搜索页面
/// 独立于主页面，键盘弹起不影响 ContentView 布局
struct SearchOverlayView: View {
    @Binding var searchText: String
    let notes: [Note]

    @Environment(\.dismiss) private var dismiss
    @FocusState private var focused: Bool
    @State private var query: String = ""

    private var results: [Note] {
        guard !query.isEmpty else { return [] }
        return notes.filter {
            $0.text.localizedCaseInsensitiveContains(query)
            || ($0.locationName?.localizedCaseInsensitiveContains(query) ?? false)
            || ($0.tags?.joined(separator: " ").localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    ContentUnavailableView("输入关键词搜索", systemImage: "magnifyingglass")
                } else if results.isEmpty {
                    ContentUnavailableView("没有找到「\(query)」", systemImage: "magnifyingglass")
                } else {
                    ForEach(results) { note in
                        SearchResultRow(note: note)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("搜索")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索笔记…")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        searchText = query
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            query = searchText
        }
    }
}

private struct SearchResultRow: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if !note.text.isEmpty {
                Text(note.text)
                    .font(.body)
                    .lineLimit(2)
            }
            HStack(spacing: 6) {
                Image(systemName: typeIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(note.timestamp, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if let loc = note.locationName {
                    Text("· \(loc)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private var typeIcon: String {
        switch note.type {
        case .video: return "video.fill"
        case .photo: return "camera.fill"
        case .mixed: return "photo.on.rectangle"
        case .text: return "pencil"
        }
    }
}

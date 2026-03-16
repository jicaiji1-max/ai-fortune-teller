import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Note.timestamp, order: .reverse) private var notes: [Note]

    @State private var showCamera = false
    @State private var showTextEditor = false
    @State private var editingNote: Note?
    @State private var searchText = ""
    @State private var selectedTag: String? = nil
    @State private var isSearching = false
    @State private var showTagManager = false
    @FocusState private var searchFocused: Bool
    @ObservedObject private var tagStore = TagStore.shared
    @ObservedObject private var previewManager = PreviewManager.shared

    private var filteredNotes: [Note] {
        notes.filter { note in
            let matchesSearch = searchText.isEmpty
                || note.text.localizedCaseInsensitiveContains(searchText)
                || (note.locationName?.localizedCaseInsensitiveContains(searchText) ?? false)
            let matchesTag = selectedTag == nil
                || (note.tags?.contains(selectedTag!) ?? false)
            return matchesSearch && matchesTag
        }
    }

    private var groupedNotes: [(String, [Note])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: filteredNotes) { note in
            calendar.startOfDay(for: note.timestamp)
        }
        let sorted = grouped.sorted { $0.key > $1.key }
        return sorted.map { (date, notes) in
            (formatGroupHeader(date), notes)
        }
    }

    var body: some View {
        ZStack {
         NavigationStack {
            ScrollView {
                Color.clear.frame(height: 0)  // 占位，避免手势冲突
                VStack(spacing: 20) {
                    // Action Buttons
                    HStack(spacing: 16) {
                        ActionButton(
                            title: "拍照",
                            systemImage: "camera.fill",
                            color: .blue,
                            gradientColors: [
                                Color(red: 0.18, green: 0.35, blue: 0.88),
                                Color(red: 0.42, green: 0.22, blue: 0.85)
                            ]
                        ) {
                            showCamera = true
                        }
                        ActionButton(
                            title: "写字",
                            systemImage: "pencil",
                            color: .purple,
                            gradientColors: [
                                Color(red: 0.52, green: 0.20, blue: 0.88),
                                Color(red: 0.78, green: 0.28, blue: 0.72)
                            ]
                        ) {
                            showTextEditor = true
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)

                    // 搜索框
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 14))
                            TextField("搜索笔记…", text: $searchText)
                                .font(.system(size: 15))
                                .focused($searchFocused)
                                .onTapGesture { isSearching = true }
                            if !searchText.isEmpty {
                                Button(action: { searchText = "" }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                        .font(.system(size: 14))
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))

                        if isSearching {
                            Button("取消") {
                                searchText = ""
                                isSearching = false
                                searchFocused = false
                            }
                            .font(.system(size: 15))
                            .foregroundStyle(Color(red: 0.20, green: 0.35, blue: 0.88))
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut(duration: 0.2), value: isSearching)

                    // 标签筛选栏
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            TagChip(title: "全部", isSelected: selectedTag == nil) {
                                selectedTag = nil
                            }
                            ForEach(tagStore.allTags, id: \.self) { tag in
                                TagChip(title: tag, isSelected: selectedTag == tag) {
                                    selectedTag = selectedTag == tag ? nil : tag
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Notes List
                    if notes.isEmpty {
                        EmptyStateView()
                            .padding(.top, 60)
                    } else {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(groupedNotes, id: \.0) { header, sectionNotes in
                                VStack(alignment: .leading, spacing: 8) {
                                    // 分组标题（不再固定）
                                    HStack(spacing: 8) {
                                        Text(header)
                                            .font(.system(size: 15, weight: .semibold))
                                            .foregroundStyle(
                                                header == "今天" || header == "昨天"
                                                ? Color(red: 0.28, green: 0.40, blue: 0.85)
                                                : Color(red: 0.28, green: 0.40, blue: 0.85).opacity(0.5)
                                            )
                                        Rectangle()
                                            .fill(Color.primary.opacity(0.08))
                                            .frame(height: 1)
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 16)

                                    // 笔记列表
                                    ForEach(sectionNotes) { note in
                                        NoteRow(note: note, onDelete: {
                                            withAnimation {
                                                modelContext.delete(note)
                                            }
                                        })
                                        .padding(.horizontal)
                                        .padding(.vertical, 4)
                                        .onTapGesture {
                                            editingNote = note
                                        }
                                        // 保留左滑删除作为第三种方式
                                        .swipeActions(edge: .trailing) {
                                            Button(role: .destructive) {
                                                withAnimation {
                                                    modelContext.delete(note)
                                                }
                                            } label: {
                                                Label("删除", systemImage: "trash")
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .background(.background)
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("随手记")
            .scrollDismissesKeyboard(.immediately)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showTagManager = true }) {
                        Image(systemName: "tag")
                            .foregroundStyle(Color(red: 0.55, green: 0.22, blue: 0.83))
                    }
                }
            }
            .sheet(isPresented: $showTagManager) {
                TagManagerView()
            }
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showCamera) {
            CameraView { photoData, additionalPhotoData, type, text, locationName, latitude, longitude, assetIdentifiers, tags, videoPaths, videoDurations, videoAssetIds in
                let note = Note(
                    type: type, text: text,
                    photoData: photoData, additionalPhotoData: additionalPhotoData,
                    locationName: locationName, latitude: latitude, longitude: longitude,
                    assetIdentifiers: assetIdentifiers, tags: tags,
                    videoPaths: videoPaths, videoDurations: videoDurations, videoAssetIds: videoAssetIds
                )
                modelContext.insert(note)
                showCamera = false
            }
        }
        .sheet(isPresented: $showTextEditor) {
            TextEditorView { text, locationName, latitude, longitude, tags in
                let note = Note(
                    type: .text,
                    text: text,
                    locationName: locationName,
                    latitude: latitude,
                    longitude: longitude,
                    tags: tags
                )
                modelContext.insert(note)
                showTextEditor = false
            }
        }
        .sheet(item: $editingNote) { note in
            if note.type == .text {
                TextEditorView(existingNote: note) { newText, newLocationName, newLatitude, newLongitude, newTags in
                    let textChanged = note.text != newText
                    let locationChanged = note.locationName != newLocationName
                    note.text = newText
                    note.locationName = newLocationName
                    note.latitude = newLatitude
                    note.longitude = newLongitude
                    note.tags = newTags
                    if textChanged || locationChanged { note.timestamp = Date() }
                    do { try modelContext.save() } catch { print("保存失败：\(error)") }
                    editingNote = nil
                }
            } else {
                CameraView(existingNote: note) { newPhotoData, newAdditionalPhotoData, newType, newText, newLocationName, newLatitude, newLongitude, newAssetIdentifiers, newTags, newVideoPaths, newVideoDurations, newVideoAssetIds in
                    let videoChanged = (note.videoPaths ?? []) != (newVideoPaths ?? [])
                    let photoChanged = (note.assetIdentifiers ?? []) != (newAssetIdentifiers ?? [])
                    let changed = note.text != newText || photoChanged || videoChanged
                        || note.type != newType || note.locationName != newLocationName
                    note.text = newText
                    note.photoData = newPhotoData
                    note.type = newType
                    note.additionalPhotoData = newAdditionalPhotoData
                    note.locationName = newLocationName
                    note.latitude = newLatitude
                    note.longitude = newLongitude
                    note.assetIdentifiers = newAssetIdentifiers
                    note.tags = newTags
                    note.videoPaths = newVideoPaths
                    note.videoDurations = newVideoDurations
                    note.videoAssetIds = newVideoAssetIds
                    if changed { note.timestamp = Date() }
                    do { try modelContext.save() } catch { print("保存失败：\(error)") }
                    editingNote = nil
                }
            }
        } // NavigationStack 结束

        // 全局预览 overlay（全屏，不受 NoteRow 尺寸限制）
        if previewManager.showPhoto {
            PhotoViewerView(uiImages: previewManager.photoImages, initialIndex: previewManager.photoIndex) {
                previewManager.dismissPhoto()
            }
            .ignoresSafeArea()
            .zIndex(999)
        }
        if previewManager.showVideo {
            VideoPlayerView(videoURLs: previewManager.videoURLs, initialIndex: previewManager.videoIndex) {
                previewManager.dismissVideo()
            }
            .ignoresSafeArea()
            .zIndex(999)
        }
        } // ZStack 结束
    }

    // 性能优化：使用 static formatter
    private static let groupHeaderFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M 月 d 日"
        return f
    }()

    private static let groupHeaderFormatterWithYear: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy 年 M 月 d 日"
        return f
    }()

    private func formatGroupHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInYesterday(date) { return "昨天" }
        // 跨年显示年份
        if calendar.component(.year, from: date) != calendar.component(.year, from: Date()) {
            return ContentView.groupHeaderFormatterWithYear.string(from: date)
        }
        return ContentView.groupHeaderFormatter.string(from: date)
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    var gradientColors: [Color]? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 36, weight: .medium))
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 110)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: gradientColors ?? [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 48))
                .foregroundStyle(.tertiary)
            Text("还没有记录")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("点击上方按钮开始记录")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
        }
    }
}

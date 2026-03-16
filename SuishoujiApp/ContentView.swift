import SwiftUI
import SwiftData
import Photos

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
    @State private var randomNote: Note? = nil
    @State private var showEmptyToast = false
    @FocusState private var searchFocused: Bool
    @ObservedObject private var tagStore = TagStore.shared

    private func restoreMissingVideos() {
        let fm = FileManager.default
        guard let docsDir = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let videosDir = docsDir.appendingPathComponent("Videos", isDirectory: true)
        try? fm.createDirectory(at: videosDir, withIntermediateDirectories: true)
        var restoreTasks: [(note: Note, pathIndex: Int, assetId: String)] = []
        for note in notes {
            guard let paths = note.videoPaths, !paths.isEmpty, let assetIds = note.videoAssetIds, !assetIds.isEmpty else { continue }
            for (i, path) in paths.enumerated() {
                let fullURL = path.hasPrefix("/") ? URL(fileURLWithPath: path) : docsDir.appendingPathComponent(path)
                if fm.fileExists(atPath: fullURL.path) { continue }
                guard i < assetIds.count, !assetIds[i].isEmpty else { continue }
                restoreTasks.append((note: note, pathIndex: i, assetId: assetIds[i]))
            }
        }
        guard !restoreTasks.isEmpty else { return }
        Task {
            for task in restoreTasks {
                if let relPath = await Self.restoreVideoFromAsset(assetId: task.assetId, videosDir: videosDir, docsDir: docsDir) {
                    if var paths = task.note.videoPaths, task.pathIndex < paths.count {
                        paths[task.pathIndex] = relPath
                        task.note.videoPaths = paths
                    }
                }
            }
        }
    }

    private static nonisolated func restoreVideoFromAsset(assetId: String, videosDir: URL, docsDir: URL) async -> String? {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = assets.firstObject else { return nil }
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: { $0.type == .video || $0.type == .fullSizeVideo }) ?? resources.first else { return nil }
        let filename = resource.originalFilename
        let ext = (filename as NSString).pathExtension
        let dest = videosDir.appendingPathComponent("restored_\(UUID().uuidString).\(ext.isEmpty ? "mov" : ext)")
        let opts = PHAssetResourceRequestOptions()
        opts.isNetworkAccessAllowed = true
        do {
            try await PHAssetResourceManager.default().writeData(for: resource, toFile: dest, options: opts)
            return String(dest.path.dropFirst(docsDir.path.count + 1))
        } catch { return nil }
    }

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
        NavigationStack {
            ScrollView {
                Color.clear.frame(height: 0)  // 占位，避免手势冲突
                VStack(spacing: 20) {
                    // Action Buttons
                    HStack(spacing: 12) {
                        ActionButton(
                            title: "定格",
                            systemImage: "camera.fill",
                            gradientColors: [
                                Color(red: 0.18, green: 0.38, blue: 0.95),
                                Color(red: 0.38, green: 0.18, blue: 0.90)
                            ]
                        ) {
                            showCamera = true
                        }
                        ActionButton(
                            title: "落笔",
                            systemImage: "pencil.line",
                            gradientColors: [
                                Color(red: 0.55, green: 0.18, blue: 0.90),
                                Color(red: 0.85, green: 0.25, blue: 0.65)
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
                            Button(action: { showTagManager = true }) {
                                Image(systemName: "plus.circle")
                                    .font(.system(size: 16))
                                    .foregroundStyle(Color(red: 0.55, green: 0.22, blue: 0.83).opacity(0.8))
                                    .padding(.horizontal, 4)
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
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        if notes.isEmpty {
                            withAnimation { showEmptyToast = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showEmptyToast = false }
                            }
                        } else {
                            randomNote = notes.randomElement()
                        }
                    }) {
                        Image(systemName: "dice")
                            .foregroundStyle(notes.isEmpty
                                ? Color(.systemGray3)
                                : Color(red: 0.55, green: 0.22, blue: 0.83))
                    }
                }
            }
            .sheet(item: $randomNote) { note in
                RandomNoteView(note: note)
            }
            .scrollDismissesKeyboard(.immediately)
            .task { restoreMissingVideos() }

            .sheet(isPresented: $showTagManager) {
                TagManagerView()
            }
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottom) {
                if showEmptyToast {
                    Text("还没有记录，先写几条吧～")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color(.darkGray).opacity(0.85), in: Capsule())
                        .padding(.bottom, 40)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
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
    var gradientColors: [Color] = [.blue, .purple]
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(LinearGradient(colors: gradientColors, startPoint: .topTrailing, endPoint: .bottomLeading))
                    .frame(height: 120)
                Image(systemName: systemImage)
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(.white.opacity(0.18))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 12).padding(.trailing, 16)
                VStack(alignment: .leading, spacing: 2) {
                    Image(systemName: systemImage)
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(.white.opacity(0.9))
                    Text(title)
                        .font(.system(size: 22, weight: .thin))
                        .tracking(3)
                        .foregroundStyle(.white)
                }
                .padding(.leading, 20).padding(.bottom, 18)
            }
            .frame(height: 120)
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .shadow(color: gradientColors.first?.opacity(0.3) ?? .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in withAnimation(.easeInOut(duration: 0.1)) { isPressed = true } }
                .onEnded { _ in withAnimation(.spring()) { isPressed = false } }
        )
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 44, weight: .ultraLight))
                .foregroundStyle(LinearGradient(
                    colors: [Color(red: 0.38, green: 0.18, blue: 0.90), Color(red: 0.85, green: 0.25, blue: 0.65)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
            Text("从这里开始")
                .font(.system(size: 18, weight: .thin))
                .tracking(2)
                .foregroundStyle(.secondary)
            Text("定格瞬间，落笔心情")
                .font(.system(size: 13))
                .foregroundStyle(.tertiary)
        }
        .padding(.top, 20)
    }
}

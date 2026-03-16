import SwiftUI
import PhotosUI
import UIKit
import Photos
import CoreLocation
import AVFoundation

// MARK: - 媒体格子（图片 or 视频）

enum MediaItem: Identifiable {
    case photo(id: String = UUID().uuidString, assetId: String, data: Data)
    case video(id: String = UUID().uuidString, url: URL, thumbnail: UIImage?, duration: Double, assetId: String?)

    var id: String {
        switch self {
        case .photo(let id, _, _): return id
        case .video(let id, _, _, _, _): return id
        }
    }

    var isVideo: Bool {
        if case .video = self { return true }
        return false
    }
}

// MARK: - CameraView

@MainActor
struct CameraView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var showImagePicker = false
    @State private var inputImage: UIImage?

    @State private var currentLocation: CLLocation?
    @State private var locationName: String?
    @State private var isFetchingLocation = false
    @State private var locationFetcher: AnyObject? = nil

    let existingNote: Note?
    // videoPaths + videoDurations 替代旧的 videoData + videoDuration
    let onSave: (Data?, [Data]?, NoteType, String, String?, Double?, Double?, [String]?, [String]?, [String]?, [Double]?, [String]?) -> Void

    // 统一媒体数组（图片 + 视频，最多9格）
    @State private var mediaItems: [MediaItem] = []
    @State private var draggingId: String? = nil

    private var photoItems: [MediaItem] { mediaItems.filter { if case .photo = $0 { return true }; return false } }
    private var videoItems: [MediaItem] { mediaItems.filter { $0.isVideo } }
    private var hasPhotos: Bool { !photoItems.isEmpty }
    private var hasVideos: Bool { !videoItems.isEmpty }
    private var hasAnyContent: Bool { !mediaItems.isEmpty }
    private var isEditMode: Bool { existingNote != nil }
    private var canAddMore: Bool { mediaItems.count < 9 }

    struct PHPickerRequest: Identifiable {
        let id = UUID()
        let preselectedIds: [String]
        let maxAdditional: Int
    }
    @State private var phPickerRequest: PHPickerRequest? = nil
    @State private var showVideoRecorder = false

    @State private var captionText = ""
    @State private var selectedTags: [String] = []
    @State private var isSaving = false
    @State private var isLoadingImage = false

    // 预览
    @State private var previewUIImages: [UIImage] = []
    @State private var previewIndex: Int = 0
    @State private var showPhotoPreview = false
    @State private var previewVideoURLs: [URL] = []
    @State private var previewVideoIndex: Int = 0
    @State private var showVideoPreview = false

    // 视频剪辑
    struct VideoTrimRequest: Identifiable {
        let id = UUID()
        let url: URL
    }
    @State private var videoToTrim: VideoTrimRequest? = nil

    init(existingNote: Note? = nil,
         onSave: @escaping (Data?, [Data]?, NoteType, String, String?, Double?, Double?, [String]?, [String]?, [String]?, [Double]?, [String]?) -> Void) {
        self.existingNote = existingNote
        self.onSave = onSave

        // 恢复图片
        let savedIds = existingNote?.assetIdentifiers ?? []
        var allImages = [Data]()
        if let main = existingNote?.photoData { allImages.append(main) }
        if let extras = existingNote?.additionalPhotoData { allImages.append(contentsOf: extras) }

        var items: [MediaItem] = []
        for (i, data) in allImages.enumerated() {
            let assetId = i < savedIds.count ? savedIds[i] : ""
            items.append(.photo(assetId: assetId, data: data))
        }

        // 恢复视频（新字段 videoPaths 优先，旧字段 videoData 兼容）
        if let paths = existingNote?.videoPaths, let durations = existingNote?.videoDurations {
            let assetIds = existingNote?.videoAssetIds ?? []
            for (i, (path, dur)) in zip(paths, durations).enumerated() {
                let url = URL(fileURLWithPath: path)
                let assetId = i < assetIds.count ? assetIds[i] : nil
                if FileManager.default.fileExists(atPath: path) {
                    items.append(.video(url: url, thumbnail: nil, duration: dur, assetId: assetId))
                }
            }
        } else if let vd = existingNote?.videoData {
            let tmpURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("edit_video_\(UUID().uuidString).mp4")
            try? vd.write(to: tmpURL)
            let dur = existingNote?.videoDuration ?? 0
            items.append(.video(url: tmpURL, thumbnail: nil, duration: dur, assetId: nil))
        }

        _mediaItems = State(initialValue: items)
        _captionText = State(initialValue: existingNote?.text ?? "")
        _selectedTags = State(initialValue: existingNote?.tags ?? [])
        _locationName = State(initialValue: existingNote?.locationName)
        _currentLocation = State(initialValue: {
            guard let lat = existingNote?.latitude, let lon = existingNote?.longitude else { return nil }
            return CLLocation(latitude: lat, longitude: lon)
        }())
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    contentSection.padding(.horizontal)
                    if !isEditMode { mediaActionBar.padding(.horizontal) }
                    locationSection
                    captionSection
                    TagSelectorView(selectedTags: $selectedTags).padding(.vertical, 4)
                    Spacer()
                }
                .padding(.top, 16)
            }
            .scrollDismissesKeyboard(.interactively)
            .task {
                // 编辑模式：为已有视频补生成缩略图（用 id 定位，避免 async 期间 index 变化）
                // 补生成缩略图，同时修正 dur == 0 的时长
                let videoItemsToFix = mediaItems.compactMap { item -> (String, URL, Double, String?)? in
                    if case .video(let vid, let url, nil, let dur, let assetId) = item {
                        return (vid, url, dur, assetId)
                    }
                    // 时长为 0 也要修正
                    if case .video(let vid, let url, let thumb, 0, let assetId) = item {
                        _ = thumb
                        return (vid, url, 0, assetId)
                    }
                    return nil
                }
                for (vid, url, dur, assetId) in videoItemsToFix {
                    async let thumbTask = generateThumbnail(from: url)
                    async let durTask: Double = dur > 0 ? dur : measureDuration(of: url)
                    let (thumb, finalDur) = await (thumbTask, durTask)
                    if let idx = mediaItems.firstIndex(where: { $0.id == vid }) {
                        mediaItems[idx] = .video(id: vid, url: url, thumbnail: thumb, duration: finalDur, assetId: assetId)
                    }
                }
            }
            .navigationTitle(isEditMode ? "编辑" : "新建笔记")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving { ProgressView().scaleEffect(0.8) }
                    else {
                        Button("保存") { save() }
                            .disabled(!hasAnyContent || isSaving)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .sheet(isPresented: $showImagePicker) { ImagePicker(image: $inputImage) }
        .fullScreenCover(isPresented: $showVideoRecorder) {
            VideoRecorderView { url, duration, assetId in
                guard let url = url else { return }
                Task { @MainActor in
                    isLoadingImage = true
                    let stableURL = Self.stableCopy(from: url) ?? url
                    let thumb = await generateThumbnail(from: stableURL)
                    mediaItems.append(.video(url: stableURL, thumbnail: thumb, duration: duration, assetId: assetId))
                    isLoadingImage = false
                }
            }
        }
        .sheet(item: $phPickerRequest) { request in
            CustomPhotoPickerView(
                preselectedIdentifiers: request.preselectedIds,
                maxSelection: request.preselectedIds.count + request.maxAdditional
            ) { items in
                guard !items.isEmpty else { return }
                Task { @MainActor in
                    isLoadingImage = true
                    // 1. 替换旧相册照片（重新选即覆盖）
                    mediaItems.removeAll { if case .photo(_, let aid, _) = $0 { return !aid.isEmpty } else { return false } }
                    // 2. 已存在 assetId 的视频不重复加（picker 预选了旧视频，但我们不需要重新写文件）
                    let existingVideoAssetIds = Set(mediaItems.compactMap { item -> String? in
                        if case .video(_, _, _, _, let aid) = item { return aid }
                        return nil
                    })
                    for item in items {
                        switch item {
                        case .photo(let id, let image):
                            if let data = image.jpegData(compressionQuality: 0.8) {
                                mediaItems.append(.photo(assetId: id, data: data))
                            }
                        case .video(let id, _, let url, let duration):
                            // 已存在的视频跳过（只有新选的视频才追加）
                            if existingVideoAssetIds.contains(id) { continue }
                            let stableURL = Self.stableCopy(from: url) ?? url
                            if duration > 5.0 {
                                videoToTrim = VideoTrimRequest(url: stableURL)
                            } else {
                                let thumb = await generateThumbnail(from: stableURL)
                                mediaItems.append(.video(url: stableURL, thumbnail: thumb, duration: duration, assetId: id))
                            }
                        }
                    }
                    isLoadingImage = false
                }
            }
        }
        .onChange(of: inputImage) { _, newImage in
            guard let image = newImage else { return }
            if let data = image.jpegData(compressionQuality: 0.8) {
                mediaItems.append(.photo(assetId: "", data: data))
                if !isEditMode { savePhotoToLibrary(image) }
            }
            inputImage = nil
        }
        // 图片预览（sheet 原生支持下滑关闭）
        // iOS 26 beta modal 黑屏：改用 overlay 直接叠在当前视图上，完全绕开 presentation
        .overlay {
            if showPhotoPreview {
                PhotoViewerView(uiImages: previewUIImages, initialIndex: previewIndex) {
                    showPhotoPreview = false
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .overlay {
            if showVideoPreview {
                VideoPlayerView(videoURLs: previewVideoURLs, initialIndex: previewVideoIndex) {
                    showVideoPreview = false
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        // 视频剪辑
        .sheet(item: $videoToTrim) { req in
            VideoTrimmerView(sourceURL: req.url) { trimmedURL in
                videoToTrim = nil
                guard let url = trimmedURL else { return }
                Task { @MainActor in
                    isLoadingImage = true
                    let stableURL = Self.stableCopy(from: url) ?? url
                    let thumb = await generateThumbnail(from: stableURL)
                    let dur = await measureDuration(of: stableURL)  // 测量实际时长
                    mediaItems.append(.video(url: stableURL, thumbnail: thumb, duration: dur, assetId: nil))
                    isLoadingImage = false
                }
            }
        }
    }



    // MARK: - 内容区

    @ViewBuilder
    private var contentSection: some View {
        if isLoadingImage {
            loadingView
        } else if mediaItems.isEmpty {
            emptyStateView
        } else {
            mediaGrid
        }
    }

    private var loadingView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .frame(height: 120)
            .overlay { VStack(spacing: 10) { ProgressView(); Text("加载中…").font(.subheadline).foregroundStyle(.secondary) } }
    }

    private var emptyStateView: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemBackground))
            .frame(maxWidth: .infinity).frame(height: 100)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo.badge.plus").font(.system(size: 30)).foregroundStyle(.tertiary)
                    Text("点击下方按钮添加照片或视频").font(.subheadline).foregroundStyle(.tertiary)
                }
            }
    }

    // 统一媒体网格（编辑 + 新建都用）
    private var mediaGrid: some View {
        VStack(alignment: .leading, spacing: 8) {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(Array(mediaItems.enumerated()), id: \.element.id) { idx, item in
                    switch item {
                    case .photo(_, _, let data):
                        if let img = UIImage(data: data) {
                            mediaCell(
                                content: { Image(uiImage: img).resizable().scaledToFill() },
                                badge: nil,
                                onTap: {
                                    // 同步转成 UIImage（mediaItems 的 Data 在内存里，不需要 async）
                                    let uiImgs = mediaItems.compactMap { item -> UIImage? in
                                        if case .photo(_, _, let d) = item { return UIImage(data: d) } else { return nil }
                                    }
                                    let photoIndex = mediaItems.prefix(idx + 1).filter {
                                        if case .photo = $0 { return true } else { return false }
                                    }.count - 1
                                    previewUIImages = uiImgs
                                    previewIndex = max(0, photoIndex)
                                    showPhotoPreview = true
                                },
                                onDelete: { mediaItems.remove(at: idx) }
                            )
                            .opacity(draggingId == item.id ? 0.5 : 1.0)
                            .onDrag {
                                draggingId = item.id
                                return NSItemProvider(object: item.id as NSString)
                            }
                            .onDrop(of: [.text], delegate: MediaDropDelegate(
                                targetId: item.id,
                                mediaItems: $mediaItems,
                                draggingId: $draggingId
                            ))
                        }
                    case .video(_, let url, let thumb, let dur, _):
                        mediaCell(
                            content: {
                                Group {
                                    if let t = thumb {
                                        Image(uiImage: t).resizable().scaledToFill()
                                    } else {
                                        Color.black.overlay(Image(systemName: "video.fill").foregroundStyle(.white.opacity(0.5)))
                                    }
                                }
                            },
                            badge: nil,
                            duration: dur,
                            onTap: {
                                let allVideoURLs = mediaItems.compactMap { item -> URL? in
                                    if case .video(_, let u, _, _, _) = item { return u } else { return nil }
                                }
                                let vidIdx = mediaItems.prefix(idx + 1).filter { $0.isVideo }.count - 1
                                previewVideoURLs = allVideoURLs
                                previewVideoIndex = max(0, vidIdx)
                                showVideoPreview = true
                            },
                            onDelete: { mediaItems.remove(at: idx) }
                        )
                        .opacity(draggingId == item.id ? 0.5 : 1.0)
                        .onDrag {
                            draggingId = item.id
                            return NSItemProvider(object: item.id as NSString)
                        }
                        .onDrop(of: [.text], delegate: MediaDropDelegate(
                            targetId: item.id,
                            mediaItems: $mediaItems,
                            draggingId: $draggingId
                        ))
                    }
                }
                // ＋ 添加按钮
                if canAddMore {
                    addMoreButton
                }
            }
            Text("\(mediaItems.count)/9 · 长按拖动排序 · 点格子预览 · 点 ✕ 删除")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private func mediaCell<Content: View>(
        @ViewBuilder content: () -> Content,
        badge: String?,
        duration: Double? = nil,
        onTap: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) -> some View {
        ZStack(alignment: .topTrailing) {
            // 图片/视频内容（被裁剪）
            content()
                .frame(minWidth: 0, maxWidth: .infinity).frame(height: 100)
                .clipped().clipShape(RoundedRectangle(cornerRadius: 8))
                .contentShape(Rectangle())
                .onTapGesture { onTap() }

            // 视频：中央播放按钮（不被裁剪）
            if duration != nil {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white.opacity(0.9), .black.opacity(0.35))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
            }

            // badge（右上角图标）
            if let badge = badge {
                Image(systemName: badge)
                    .font(.system(size: 16))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(6)
                    .allowsHitTesting(false)
            }

            // 视频时长（左下角，不被裁剪）
            if let dur = duration {
                VStack {
                    Spacer()
                    HStack {
                        Text(formatDuration(dur))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.8), radius: 2)
                            .padding(.horizontal, 5).padding(.vertical, 2)
                            .background(Color.black.opacity(0.65), in: Capsule())
                            .padding(4)
                        Spacer()
                    }
                }
                .allowsHitTesting(false)
            }

            // 删除按钮
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .black.opacity(0.7))
                    .font(.title3)
            }
            .padding(4)
        }
        .frame(minWidth: 0, maxWidth: .infinity).frame(height: 100)
    }

    private var addMoreButton: some View {
        Button(action: { openPHPicker() }) {
            VStack(spacing: 6) {
                Image(systemName: "plus").font(.title2).foregroundStyle(.blue)
                Text("添加").font(.caption).foregroundStyle(.blue)
            }
            .frame(minWidth: 0, maxWidth: .infinity).frame(height: 100)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.blue.opacity(0.4), style: StrokeStyle(lineWidth: 1, dash: [4])))
        }
    }

    // MARK: - 媒体操作栏（新建模式）

    private var mediaActionBar: some View {
        HStack(spacing: 0) {
            MediaActionButton(icon: "camera.fill", label: "拍照", color: Color(red: 0.18, green: 0.45, blue: 0.95)) {
                showImagePicker = true
            }
            Divider().frame(height: 36)
            MediaActionButton(icon: "photo.on.rectangle", label: "相册", color: Color(red: 0.18, green: 0.45, blue: 0.95)) {
                openPHPicker()
            }
            Divider().frame(height: 36)
            MediaActionButton(icon: "video.fill", label: "录视频", color: Color(red: 0.18, green: 0.45, blue: 0.95)) {
                showVideoRecorder = true
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - 位置

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("位置（可选）").font(.subheadline).foregroundStyle(.secondary)
                Spacer()
                if isFetchingLocation { ProgressView().scaleEffect(0.8) }
            }
            .padding(.horizontal)
            if let name = locationName {
                HStack(spacing: 6) {
                    Text("📍 \(name)").font(.caption).foregroundStyle(.secondary)
                    Button(action: { locationName = nil; currentLocation = nil }) {
                        Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary).font(.caption)
                    }
                }
                .padding(.horizontal)
            }
            Button(action: fetchCurrentLocation) {
                HStack(spacing: 4) {
                    Image(systemName: locationName != nil ? "location.fill" : "location").font(.caption)
                    Text(locationName != nil ? "更新位置" : "获取当前位置").font(.caption).fontWeight(.medium)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(locationName != nil ? Color.green.opacity(0.9) : Color.blue.opacity(0.9), in: Capsule())
            }
            .disabled(isFetchingLocation)
            .padding(.horizontal)
        }
    }

    // MARK: - 说明

    private var captionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("记录感受（可选）").font(.subheadline).foregroundStyle(.secondary).padding(.horizontal)
            TextEditor(text: $captionText)
                .frame(minHeight: 80).padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
        }
    }

    // MARK: - 辅助

    private func openPHPicker() {
        let photoAssetIds = mediaItems.compactMap { item -> String? in
            if case .photo(_, let aid, _) = item { return aid.isEmpty ? nil : aid }
            return nil
        }
        let videoAssetIds = mediaItems.compactMap { item -> String? in
            if case .video(_, _, _, _, let aid) = item { return aid }
            return nil
        }
        let preselected = photoAssetIds + videoAssetIds
        let remaining = max(1, 9 - mediaItems.count)
        phPickerRequest = PHPickerRequest(preselectedIds: preselected, maxAdditional: remaining)
    }

    private func formatDuration(_ s: Double) -> String {
        let t = max(1, Int(ceil(s)))
        return t < 60 ? "\(t)s" : "\(t/60):\(String(format: "%02d", t%60))"
    }

    private func savePhotoToLibrary(_ image: UIImage) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            guard status == .authorized || status == .limited else { return }
            var placeholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                let req = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeholder = req.placeholderForCreatedAsset
            }, completionHandler: { success, _ in
                guard success, let assetId = placeholder?.localIdentifier, !assetId.isEmpty else { return }
                DispatchQueue.main.async {
                    if let data = image.jpegData(compressionQuality: 0.8) {
                        // 把刚加的相机照片（assetId=""）替换为有 assetId 的版本
                        if let idx = self.mediaItems.firstIndex(where: {
                            if case .photo(_, let aid, let d) = $0 { return aid.isEmpty && d == data }
                            return false
                        }) {
                            self.mediaItems[idx] = .photo(assetId: assetId, data: data)
                        }
                    }
                }
            })
        }
    }

    private func fetchCurrentLocation() {
        isFetchingLocation = true
        class LocationFetcher: NSObject, CLLocationManagerDelegate {
            var completionHandler: ((CLLocation?, String?) -> Void)?
            let manager = CLLocationManager()
            var isCompleted = false
            override init() { super.init(); manager.delegate = self }
            func start() { manager.requestWhenInUseAuthorization(); manager.startUpdatingLocation() }
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                guard let location = locations.last, !isCompleted else { return }
                isCompleted = true
                manager.stopUpdatingLocation()
                CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                    var name: String?
                    if let p = placemarks?.first {
                        name = [p.name, p.locality].compactMap { $0 }.joined(separator: " ")
                    }
                    self.completionHandler?(location, name)
                }
            }
            func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
                guard !isCompleted else { return }
                isCompleted = true
                completionHandler?(nil, nil)
            }
        }
        let fetcher = LocationFetcher()
        locationFetcher = fetcher
        fetcher.completionHandler = { loc, name in
            Task { @MainActor in
                self.currentLocation = loc
                self.locationName = name
                self.isFetchingLocation = false
                self.locationFetcher = nil
            }
        }
        fetcher.start()
    }

    private func save() {
        isSaving = true
        let trimmedText = captionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lat = currentLocation?.coordinate.latitude
        let lon = currentLocation?.coordinate.longitude
        let tags = selectedTags.isEmpty ? nil : selectedTags

        // 收集图片
        let photoDataList = mediaItems.compactMap { item -> Data? in
            if case .photo(_, _, let data) = item { return UIImage(data: data)?.jpegData(compressionQuality: 0.7) }
            return nil
        }
        let mainPhoto = photoDataList.first
        let extraPhotos = photoDataList.count > 1 ? Array(photoDataList.dropFirst()) : nil

        // 收集图片 assetId
        let allIds = mediaItems.compactMap { item -> String? in
            if case .photo(_, let aid, _) = item { return aid }
            return nil
        }
        let hasAnyId = allIds.contains { !$0.isEmpty }

        // 收集视频（存路径 + assetId）
        var videoPaths: [String] = []
        var videoDurations: [Double] = []
        var videoAssetIds: [String] = []
        for item in mediaItems {
            if case .video(_, let url, _, let dur, let assetId) = item {
                let stableURL = Self.stableCopy(from: url) ?? url
                videoPaths.append(stableURL.path)
                videoDurations.append(dur)
                videoAssetIds.append(assetId ?? "")
            }
        }

        let type: NoteType
        if !videoPaths.isEmpty && photoDataList.isEmpty { type = .video }
        else if !videoPaths.isEmpty || photoDataList.count > 1 || !trimmedText.isEmpty { type = .mixed }
        else { type = .photo }

        onSave(
            mainPhoto, extraPhotos, type, trimmedText,
            locationName, lat, lon,
            hasAnyId ? allIds : nil,
            tags,
            videoPaths.isEmpty ? nil : videoPaths,
            videoDurations.isEmpty ? nil : videoDurations,
            videoAssetIds.isEmpty ? nil : videoAssetIds
        )
        isSaving = false
        dismiss()
    }

    static func stableCopy(from url: URL) -> URL? {
        let fm = FileManager.default
        // 如果已经在 Documents/Videos 下，直接返回
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            let videosDir = docs.appendingPathComponent("Videos", isDirectory: true)
            if url.path.hasPrefix(videosDir.path) { return url }
        }
        guard let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first else { return nil }
        let videosDir = docs.appendingPathComponent("Videos", isDirectory: true)
        try? fm.createDirectory(at: videosDir, withIntermediateDirectories: true)
        // 保留原始扩展名，避免 .mov 内容被错误地写成 .mp4 容器
        let ext = url.pathExtension.isEmpty ? "mp4" : url.pathExtension
        let dest = videosDir.appendingPathComponent("video_\(UUID().uuidString).\(ext)")
        do {
            try fm.copyItem(at: url, to: dest)
            return dest
        } catch {
            print("[CameraView] stableCopy failed: \(error)")
            return nil
        }
    }

    private func measureDuration(of url: URL) async -> Double {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = AVAsset(url: url)
                let duration = asset.duration.seconds
                continuation.resume(returning: duration.isNaN ? 5.0 : max(0.3, duration))
            }
        }
    }

    private func generateThumbnail(from url: URL) async -> UIImage? {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let asset = AVAsset(url: url)
                let gen = AVAssetImageGenerator(asset: asset)
                gen.appliesPreferredTrackTransform = true
                if let cg = try? gen.copyCGImage(at: .zero, actualTime: nil) {
                    continuation.resume(returning: UIImage(cgImage: cg))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// MARK: - MediaActionButton

private struct MediaActionButton: View {
    let icon: String; let label: String; let color: Color; let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 24)).foregroundStyle(color)
                Text(label).font(.system(size: 13)).foregroundStyle(color)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 拖拽排序 Delegate

struct MediaDropDelegate: DropDelegate {
    let targetId: String
    @Binding var mediaItems: [MediaItem]
    @Binding var draggingId: String?

    func performDrop(info: DropInfo) -> Bool {
        draggingId = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let fromId = draggingId,
              fromId != targetId,
              let fromIdx = mediaItems.firstIndex(where: { $0.id == fromId }),
              let toIdx = mediaItems.firstIndex(where: { $0.id == targetId })
        else { return }
        withAnimation { mediaItems.move(fromOffsets: IndexSet(integer: fromIdx), toOffset: toIdx > fromIdx ? toIdx + 1 : toIdx) }
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - ImagePicker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.delegate = context.coordinator
        p.sourceType = .camera
        p.cameraCaptureMode = .photo
        return p
    }
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.image = image }
            picker.dismiss(animated: true)
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }
    }
}

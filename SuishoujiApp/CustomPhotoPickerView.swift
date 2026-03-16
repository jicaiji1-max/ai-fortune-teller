import SwiftUI
import Photos
import UIKit
import AVFoundation

/// 选择结果：照片或视频
enum PickerItem {
    case photo(id: String, image: UIImage)
    case video(id: String, thumbnail: UIImage?, url: URL, duration: Double)
}

/// 自定义图片/视频选择器
/// 使用 PHAsset API，支持预选高亮、照片+视频混合、视频大小限制
struct CustomPhotoPickerView: View {

    let preselectedIdentifiers: [String]
    let maxSelection: Int
    var onComplete: ([PickerItem]) -> Void

    // 视频大小上限（200 MB）
    static let maxVideoSizeBytes: Int64 = 200 * 1024 * 1024

    @Environment(\.dismiss) private var dismiss
    @State private var assets: [PHAsset] = []
    @State private var selectedIds: [String]
    @State private var thumbnailCache: [String: UIImage] = [:]
    @State private var authStatus: PHAuthorizationStatus = .notDetermined
    @State private var isLoading = true
    @State private var isConfirming = false
    @State private var oversizedVideoAlert = false

    init(preselectedIdentifiers: [String],
         maxSelection: Int,
         onComplete: @escaping ([PickerItem]) -> Void) {
        self.preselectedIdentifiers = preselectedIdentifiers
        self.maxSelection = maxSelection
        self.onComplete = onComplete
        // 在 init 就初始化 selectedIds，确保 cell 首次渲染时就有正确值
        _selectedIds = State(initialValue: preselectedIdentifiers.filter { !$0.isEmpty })
    }

    private let columns = [GridItem(.flexible(), spacing: 2),
                           GridItem(.flexible(), spacing: 2),
                           GridItem(.flexible(), spacing: 2)]

    var body: some View {
        // 不用 NavigationStack —— iOS 26 beta 中 NavigationStack 在 sheet 里黑屏
        // 改用自绘 header + 内容区，完全绕开该 bug
        VStack(spacing: 0) {
            // ── 自绘导航栏 ──
            ZStack {
                Text("选择照片/视频")
                    .font(.headline)
                HStack {
                    Button("取消") { dismiss(); onComplete([]) }
                        .disabled(isConfirming)
                    Spacer()
                    if isConfirming {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Button("完成(\(selectedIds.count))") {
                            isConfirming = true
                            confirmSelection()
                        }
                        .fontWeight(.semibold)
                        .disabled(selectedIds.isEmpty)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))

            Divider()

            // ── 内容区 ──
            Group {
                if authStatus == .denied || authStatus == .restricted {
                    permissionDeniedView
                } else if isLoading {
                    ProgressView("加载相册…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    photoGridView
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemBackground))
        }
        .background(Color(.systemBackground))
        .alert("视频太大", isPresented: $oversizedVideoAlert) {
            Button("知道了", role: .cancel) {}
        } message: {
            Text("视频文件超过 200MB，无法选择。请选择较小的视频。")
        }
        .onAppear { setup() }
    }

    // MARK: - 网格

    private var photoGridView: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(assets, id: \.localIdentifier) { asset in
                    let selIdx = selectedIndex(for: asset.localIdentifier)
                    AssetCell(
                        asset: asset,
                        selectionIndex: selIdx,
                        thumbnail: thumbnailCache[asset.localIdentifier],
                        onThumbnailLoaded: { img in
                            thumbnailCache[asset.localIdentifier] = img
                        }
                    )
                    // .id 包含 selectionIndex，选中状态变化时强制 SwiftUI 重新渲染 cell
                    .id("\(asset.localIdentifier)-\(selIdx ?? 0)")
                    .onTapGesture { toggle(asset) }
                }
            }
            .padding(.horizontal, 1)
        }
    }

    // MARK: - 权限拒绝

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 50)).foregroundStyle(.secondary)
            Text("需要相册访问权限").font(.headline)
            Text("请前往设置 → 随手记 → 照片，选择「所有照片」")
                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Button("打开设置") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - 逻辑

    private func setup() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        authStatus = status
        if status == .authorized || status == .limited {
            loadAssets()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    authStatus = newStatus
                    if newStatus == .authorized || newStatus == .limited {
                        loadAssets()
                    } else {
                        isLoading = false
                    }
                }
            }
        } else {
            isLoading = false
        }
    }

    private func loadAssets() {
        DispatchQueue.global(qos: .userInitiated).async {
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            // 只取图片和视频
            options.predicate = NSPredicate(format: "mediaType == %d OR mediaType == %d",
                                            PHAssetMediaType.image.rawValue,
                                            PHAssetMediaType.video.rawValue)
            let result = PHAsset.fetchAssets(with: options)
            var loaded: [PHAsset] = []
            result.enumerateObjects { asset, _, _ in loaded.append(asset) }
            DispatchQueue.main.async {
                assets = loaded
                isLoading = false
            }
        }
    }

    private func selectedIndex(for id: String) -> Int? {
        selectedIds.firstIndex(of: id).map { $0 + 1 }
    }

    private func toggle(_ asset: PHAsset) {
        let id = asset.localIdentifier

        // 已选中 → 取消
        if let idx = selectedIds.firstIndex(of: id) {
            selectedIds.remove(at: idx)
            return
        }

        if asset.mediaType == .video {
            if asset.duration > 300 {
                oversizedVideoAlert = true
                return
            }
            // 多视频支持：不再限制只能选一个，由 maxSelection 控制总数
        }

        guard selectedIds.count < maxSelection else { return }
        selectedIds.append(id)
    }

    private func confirmSelection() {
        let ids = selectedIds
        let assetSnapshot = assets
        guard !ids.isEmpty else { onComplete([]); return }

        Task {
            var ordered: [PickerItem] = []
            for id in ids {
                guard let asset = assetSnapshot.first(where: { $0.localIdentifier == id }) else { continue }
                if asset.mediaType == .video {
                    if let item = await fetchVideo(asset: asset, id: id) {
                        ordered.append(item)
                    }
                } else {
                    if let item = await fetchPhoto(asset: asset, id: id) {
                        ordered.append(item)
                    }
                }
            }
            dismiss()
            onComplete(ordered)
        }
    }

    // 用 nonisolated + continuation 从后台安全桥接，避免 Swift 6 actor isolation crash
    private nonisolated func fetchPhoto(asset: PHAsset, id: String) async -> PickerItem? {
        await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            manager.requestImage(
                for: asset,
                targetSize: CGSize(width: 1200, height: 1200),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                if let img = image {
                    continuation.resume(returning: .photo(id: id, image: img))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private nonisolated func fetchVideo(asset: PHAsset, id: String) async -> PickerItem? {
        let duration = asset.duration

        // 1. 缩略图（后台 PHImageManager 回调，不在 @MainActor 上）
        let thumb: UIImage? = await withCheckedContinuation { continuation in
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            manager.requestImage(for: asset,
                                 targetSize: CGSize(width: 300, height: 300),
                                 contentMode: .aspectFill,
                                 options: options) { img, _ in
                continuation.resume(returning: img)
            }
        }

        // 2. 写视频文件
        let resources = PHAssetResource.assetResources(for: asset)
        guard let resource = resources.first(where: {
            $0.type == .video || $0.type == .fullSizeVideo || $0.type == .pairedVideo
        }) ?? resources.first else { return nil }

        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("album_video_\(UUID().uuidString).mov")
        let writeOptions = PHAssetResourceRequestOptions()
        writeOptions.isNetworkAccessAllowed = true

        let success: Bool = await withCheckedContinuation { continuation in
            PHAssetResourceManager.default().writeData(for: resource, toFile: dest, options: writeOptions) { error in
                continuation.resume(returning: error == nil)
            }
        }

        guard success else { return nil }
        return .video(id: id, thumbnail: thumb, url: dest, duration: duration)
    }
}

// MARK: - 单格 Cell

private struct AssetCell: View {
    let asset: PHAsset
    let selectionIndex: Int?
    let thumbnail: UIImage?
    let onThumbnailLoaded: (UIImage) -> Void

    private var isVideo: Bool { asset.mediaType == .video }
    private var cellSize: CGFloat { (UIScreen.main.bounds.width - 6) / 3 }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // 图片 / 占位
            Group {
                if let img = thumbnail {
                    Image(uiImage: img)
                        .resizable().scaledToFill()
                        .frame(width: cellSize, height: cellSize).clipped()
                } else {
                    Color(.secondarySystemBackground)
                        .frame(width: cellSize, height: cellSize)
                        .overlay(ProgressView().scaleEffect(0.6))
                }
            }

            // 选中蒙层
            if selectionIndex != nil {
                Color.blue.opacity(0.2)
                    .frame(width: cellSize, height: cellSize)
                    .allowsHitTesting(false)
            }

            // 选中序号 / 空圈
            selectionBadge
                .padding(6)
                .allowsHitTesting(false)
        }
        // 视频底部：时长 + 视频图标
        .overlay(alignment: .bottomLeading) {
            if isVideo {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill").font(.system(size: 9))
                    Text(formatDuration(asset.duration))
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 5).padding(.vertical, 3)
                .background(Color.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 4))
                .padding(4)
                .allowsHitTesting(false)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .contentShape(Rectangle())
        .onAppear { loadThumbnail() }
    }

    @ViewBuilder
    private var selectionBadge: some View {
        if let index = selectionIndex {
            Circle()
                .fill(Color.blue).frame(width: 28, height: 28)
                .overlay(Text("\(index)").font(.system(size: 14, weight: .bold)).foregroundStyle(.white))
        } else {
            Circle()
                .fill(Color.black.opacity(0.25)).frame(width: 28, height: 28)
                .overlay(Circle().strokeBorder(Color.white, lineWidth: 2).frame(width: 28, height: 28))
        }
    }

    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast
        options.isSynchronous = false
        let size = CGSize(width: 240, height: 240)
        manager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: options) { img, _ in
            if let img = img {
                DispatchQueue.main.async { onThumbnailLoaded(img) }
            }
        }
    }

    private func formatDuration(_ seconds: Double) -> String {
        let t = max(1, Int(ceil(seconds)))
        return t < 60 ? "\(t)s" : "\(t/60):\(String(format: "%02d", t%60))"
    }
}

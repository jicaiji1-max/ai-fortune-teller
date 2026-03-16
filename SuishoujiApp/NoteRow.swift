import SwiftUI
import UIKit
import AVFoundation

struct NoteRow: View {
    let note: Note
    var onDelete: () -> Void
    
    @State private var showDeleteAlert = false
    // 异步加载主图（externalStorage fault 需要时间）
    @State private var mainImage: UIImage? = nil
    private let preview = PreviewManager.shared
    
    // 性能优化：使用 static formatter
    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f
    }()

    private var timeString: String {
        NoteRow.timeFormatter.string(from: note.timestamp)
    }
    
    // 计算图片总数
    private var imageCount: Int {
        let mainImage = note.photoData != nil ? 1 : 0
        let additionalImages = note.additionalPhotoData?.count ?? 0
        return mainImage + additionalImages
    }
    
    // 是否有视频
    private var hasVideo: Bool { !note.videoURLs.isEmpty }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Thumbnail 区域
            thumbnailSection
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                if !note.text.isEmpty {
                    Text(note.text)
                        .font(.body)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                // 元信息行（支持 wrap 溢出）
                metaInfoView
            }

            // 右上角删除按钮
            Button(role: .destructive) {
                showDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .padding(8)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        // 长按删除
        .onLongPressGesture {
            showDeleteAlert = true
        }
        .alert("确认删除", isPresented: $showDeleteAlert) {
            Button("取消", role: .cancel) { }
            Button("删除", role: .destructive) { onDelete() }
        } message: {
            Text("此操作无法撤销")
        }

    }
    
    // MARK: - 缩略图区域
    
    @ViewBuilder
    private var thumbnailSection: some View {
        let totalMedia = imageCount + note.videoURLs.count

        // 优先用异步加载好的 mainImage；note.photoData 不为 nil 但 fault 未完成时显示占位
        if note.photoData != nil {
            let uiImage = mainImage
            ZStack(alignment: .bottomTrailing) {
                if let uiImage = uiImage {
                    Image(uiImage: uiImage)
                        .resizable().scaledToFill()
                        .frame(width: 72, height: 72).clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    // externalStorage 还在 fault 中 —— 显示灰色占位
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                        .frame(width: 72, height: 72)
                        .overlay(ProgressView().scaleEffect(0.7))
                }
                if hasVideo {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(.white.opacity(0.9), .black.opacity(0.4))
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .allowsHitTesting(false)
                }
                if totalMedia > 1 { mediaBadgeView }
            }
            .frame(width: 72, height: 72)
            .task(id: note.id) {
                // 异步 fault externalStorage，有重试（SwiftData 刚 insert 后可能需要稍等）
                for attempt in 0..<5 {
                    if let data = note.photoData, let img = UIImage(data: data) {
                        mainImage = img
                        break
                    }
                    if attempt < 4 {
                        try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
                    }
                }
            }
            .onTapGesture {
                // 合并图片+视频为混合列表，点哪个就从哪个开始
                var mixedItems: [MediaPreviewItem] = []
                var tapIndex = 0
                if let d = note.photoData, let img = UIImage(data: d) { mixedItems.append(.photo(img)) }
                for d in note.additionalPhotoData ?? [] {
                    if let img = UIImage(data: d) { mixedItems.append(.photo(img)) }
                }
                if hasVideo {
                    tapIndex = mixedItems.count  // 点的是第一张图，视频在后面
                    for url in note.videoURLs { mixedItems.append(.video(url)) }
                    // 如果点的是图片缩略图（有图），从图片开始
                    tapIndex = 0
                }
                preview.present(items: mixedItems, index: tapIndex)
            }
        } else if hasVideo, let videoURL = note.videoURLs.first {
            ZStack(alignment: .bottomTrailing) {
                VideoThumbnailView(videoURL: videoURL)
                    .frame(width: 72, height: 72)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(.white.opacity(0.9), .black.opacity(0.4))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .allowsHitTesting(false)
                mediaBadgeView
            }
            .frame(width: 72, height: 72)
            .onTapGesture {
                // 纯视频，直接打开视频列表
                preview.presentVideos(note.videoURLs)
            }
        }
    }

    private func mediaBadgeLabel() -> String {
        let vCount = note.videoURLs.count
        if imageCount == 0, vCount == 1 {
            return "🎬 \(formatDuration(note.allVideoDurations.first ?? 0))"
        } else if imageCount == 0 {
            return "🎬 \(vCount)"
        } else {
            return "⊞ \(imageCount + vCount)"
        }
    }

    private var mediaBadgeView: some View {
        Text(mediaBadgeLabel())
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6).padding(.vertical, 3)
            .background(Color.black.opacity(0.7), in: Capsule())
            .padding(4)
    }
    
    // MARK: - 元信息（icon + 时间 + 图片数 / 视频时长 + 位置 + 标签）
    
    private var metaInfoView: some View {
        // 用 FlowLayout 风格：超出自动换行
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                // 类型图标
                Image(systemName: typeIcon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(timeString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                // 媒体摘要（缩略图角标已有数量，这里只补充没在角标里的信息）
                let vCount = note.videoURLs.count
                if imageCount > 0 && vCount > 0 {
                    Text("· \(imageCount)图 \(vCount)视频")
                        .font(.caption).foregroundStyle(.secondary)
                } else if imageCount > 1 {
                    Text("· \(imageCount) 张图片")
                        .font(.caption).foregroundStyle(.secondary)
                } else if vCount > 0 {
                    let totalDur = note.allVideoDurations.reduce(0, +)
                    if vCount > 1 {
                        Text("· \(vCount) 个视频 共\(formatDuration(totalDur))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // 位置（独行）
            if let location = note.locationName {
                Text("📍 \(location)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            
            // 标签（每个单独胶囊，wrap 展示）
            if let tags = note.tags, !tags.isEmpty {
                WrappingTagsView(tags: tags)
            }
        }
    }
    
    private var typeIcon: String {
        switch note.type {
        case .video:   return "video.fill"
        case .photo:   return "camera.fill"
        case .mixed:   return "photo.on.rectangle"
        case .text:    return "pencil"
        }
    }
    
    private func formatDuration(_ seconds: Double) -> String {
        let s = max(1, Int(ceil(seconds)))
        return s < 60 ? "\(s)s" : "\(s/60):\(String(format: "%02d", s%60))"
    }
}

// MARK: - 标签 Wrap 展示

private struct WrappingTagsView: View {
    let tags: [String]
    
    var body: some View {
        // iOS 16+ 可用 Layout，这里用简单的 HStack + 自动截断
        // 显示所有标签，超出的用 +N 表示
        HStack(spacing: 4) {
            ForEach(Array(tags.prefix(3).enumerated()), id: \.offset) { _, tag in
                Text(tag)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(red: 0.55, green: 0.22, blue: 0.83))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.55, green: 0.22, blue: 0.83).opacity(0.1), in: Capsule())
                    .lineLimit(1)
            }
            if tags.count > 3 {
                Text("+\(tags.count - 3)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(.systemGray5), in: Capsule())
            }
        }
    }
}

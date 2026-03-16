import SwiftUI
import AVKit
import AVFoundation

/// 全屏视频播放器 - 支持 overlay 模式（绕开 iOS 26 modal 黑屏 bug）
struct VideoPlayerView: View {
    let videoURLs: [URL]
    var initialIndex: Int = 0
    var onDismiss: (() -> Void)? = nil

    init(videoURL: URL, onDismiss: (() -> Void)? = nil) {
        self.videoURLs = [videoURL]
        self.initialIndex = 0
        self.onDismiss = onDismiss
    }

    init(videoURLs: [URL], initialIndex: Int = 0, onDismiss: (() -> Void)? = nil) {
        self.videoURLs = videoURLs
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
    }

    @State private var currentIndex: Int = 0
    @State private var players: [URL: AVPlayer] = [:]
    @Environment(\.dismiss) private var envDismiss

    private func dismiss() {
        players.values.forEach { $0.pause() }
        if let onDismiss = onDismiss { onDismiss() } else { envDismiss() }
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            if videoURLs.isEmpty {
                Text("无视频").foregroundStyle(.white)
            } else if videoURLs.count == 1 {
                VideoPlayer(player: playerFor(videoURLs[0]))
                    .ignoresSafeArea()
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(videoURLs.enumerated()), id: \.offset) { idx, url in
                        VideoPlayer(player: playerFor(url))
                            .ignoresSafeArea()
                            .tag(idx)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .ignoresSafeArea()
                .onChange(of: currentIndex) { _, newIdx in
                    players.values.forEach { $0.pause() }
                    playerFor(videoURLs[newIdx]).play()
                }
            }

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white.opacity(0.8), .black.opacity(0.4))
            }
            .padding(20)
        }
        .onAppear {
            currentIndex = initialIndex
            if !videoURLs.isEmpty {
                playerFor(videoURLs[min(initialIndex, videoURLs.count - 1)]).play()
            }
        }
        .onDisappear { players.values.forEach { $0.pause() } }
        .statusBarHidden(true)
    }

    @discardableResult
    private func playerFor(_ url: URL) -> AVPlayer {
        if let existing = players[url] { return existing }
        let p = AVPlayer(url: url)
        players[url] = p
        return p
    }
}

/// 视频缩略图 - 接受 URL
struct VideoThumbnailView: View {
    let videoURL: URL
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack {
            if let img = thumbnail {
                Image(uiImage: img).resizable().scaledToFill()
            } else {
                Color.black
            }
            Image(systemName: "play.circle.fill")
                .font(.system(size: 28))
                .foregroundStyle(.white.opacity(0.9), .black.opacity(0.3))
        }
        .onAppear { loadThumbnail() }
    }

    private func loadThumbnail() {
        guard thumbnail == nil else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let asset = AVAsset(url: videoURL)
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            if let cg = try? gen.copyCGImage(at: .zero, actualTime: nil) {
                DispatchQueue.main.async { thumbnail = UIImage(cgImage: cg) }
            }
        }
    }
}

/// Data → 临时文件，供旧数据兼容使用
struct VideoDataPlayerView: View {
    let videoData: Data
    @State private var tempURL: URL?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let url = tempURL {
                VideoPlayerView(videoURL: url)
            } else {
                Color.black.ignoresSafeArea()
                    .overlay(ProgressView().tint(.white))
            }
        }
        .onAppear { prepareURL() }
    }

    private func prepareURL() {
        let hash = videoData.hashValue
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("play_\(hash).mp4")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? videoData.write(to: url)
        }
        tempURL = url
    }
}

/// Data → 缩略图，旧数据兼容
struct VideoDataThumbnailView: View {
    let videoData: Data
    @State private var thumbnailURL: URL?

    var body: some View {
        Group {
            if let url = thumbnailURL {
                VideoThumbnailView(videoURL: url)
            } else {
                Color(.secondarySystemBackground)
                    .overlay(Image(systemName: "video.fill").foregroundStyle(.tertiary))
            }
        }
        .onAppear { prepareURL() }
    }

    private func prepareURL() {
        guard thumbnailURL == nil else { return }
        let hash = videoData.hashValue
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("thumb_\(hash).mp4")
        if !FileManager.default.fileExists(atPath: url.path) {
            try? videoData.write(to: url)
        }
        thumbnailURL = url
    }
}

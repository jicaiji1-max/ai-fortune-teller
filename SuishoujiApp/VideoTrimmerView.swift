import SwiftUI
import AVFoundation
import AVKit

/// 自定义视频剪辑视图
/// - 底部时间轴 + 左右拖柄，初始直接选中前5秒（无动效）
/// - 确认后导出选中片段
struct VideoTrimmerView: View {
    let sourceURL: URL
    var onComplete: (URL?) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var player: AVPlayer?
    @State private var duration: Double = 0
    @State private var startTime: Double = 0
    @State private var endTime: Double = 5.0
    @State private var isExporting = false
    @State private var thumbnails: [UIImage] = []

    private let maxClipDuration: Double = 5.0
    private let thumbCount = 8

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                // 顶部工具栏
                HStack {
                    Button("取消") {
                        player?.pause()
                        dismiss()
                        onComplete(nil)
                    }
                    .foregroundStyle(.white)
                    Spacer()
                    Text("剪辑视频")
                        .font(.headline).foregroundStyle(.white)
                    Spacer()
                    if isExporting {
                        ProgressView().tint(.white)
                    } else {
                        Button("完成") { exportClip() }
                            .foregroundStyle(.yellow)
                            .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 14)

                // 视频预览
                if let player = player {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture { togglePlayback() }
                }

                // 底部剪辑区
                VStack(spacing: 10) {
                    // 时间标签
                    HStack {
                        Text(formatTime(startTime))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                        Spacer()
                        Text(formatTime(endTime - startTime) + " / 最长5秒")
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.yellow)
                        Spacer()
                        Text(formatTime(endTime))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 20)

                    // 时间轴
                    GeometryReader { geo in
                        let w = geo.size.width
                        let handleW: CGFloat = 14
                        let trackW = w - handleW * 2

                        ZStack(alignment: .leading) {
                            // 缩略图条
                            HStack(spacing: 0) {
                                ForEach(Array(thumbnails.enumerated()), id: \.offset) { _, img in
                                    Image(uiImage: img)
                                        .resizable().scaledToFill()
                                        .frame(width: trackW / CGFloat(thumbCount), height: 50)
                                        .clipped()
                                }
                            }
                            .frame(width: trackW, height: 50)
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                            .offset(x: handleW)

                            // 灰色遮罩（选中区域外）
                            let startX = handleW + CGFloat(startTime / duration) * trackW
                            let endX = handleW + CGFloat(endTime / duration) * trackW

                            // 左侧遮罩
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: max(0, startX - handleW), height: 50)
                                .offset(x: handleW)

                            // 右侧遮罩
                            Rectangle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: max(0, w - endX - handleW), height: 50)
                                .offset(x: endX)

                            // 选中框边框
                            Rectangle()
                                .stroke(Color.yellow, lineWidth: 2)
                                .frame(width: max(0, endX - startX), height: 54)
                                .offset(x: startX)

                            // 左拖柄
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.yellow)
                                .frame(width: handleW, height: 54)
                                .offset(x: startX - handleW / 2)
                                .overlay(
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.black)
                                        .offset(x: startX - handleW / 2)
                                )
                                .gesture(DragGesture().onChanged { v in
                                    let newT = Double((v.location.x - handleW) / trackW) * duration
                                    let clamped = max(0, min(newT, endTime - 0.5))
                                    // 保证 end - start <= maxClipDuration
                                    startTime = max(clamped, endTime - maxClipDuration)
                                    seekPlayer(to: startTime)
                                })

                            // 右拖柄
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.yellow)
                                .frame(width: handleW, height: 54)
                                .offset(x: endX - handleW / 2)
                                .overlay(
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.black)
                                        .offset(x: endX - handleW / 2)
                                )
                                .gesture(DragGesture().onChanged { v in
                                    let newT = Double((v.location.x - handleW) / trackW) * duration
                                    let clamped = min(duration, max(newT, startTime + 0.5))
                                    // 保证 end - start <= maxClipDuration
                                    endTime = min(clamped, startTime + maxClipDuration)
                                    seekPlayer(to: startTime)
                                })
                        }
                        .frame(height: 54)
                    }
                    .frame(height: 54)
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 16)
                .background(Color(white: 0.1))
            }
        }
        .statusBarHidden(true)
        .onAppear { setup() }
        .onDisappear { player?.pause() }
    }

    // MARK: - Setup

    private func setup() {
        let asset = AVAsset(url: sourceURL)
        let dur = asset.duration.seconds
        guard dur > 0 else { return }
        duration = dur
        // 初始直接选前5秒，无动效
        startTime = 0
        endTime = min(maxClipDuration, dur)

        let p = AVPlayer(url: sourceURL)
        player = p
        p.play()

        generateThumbnails(asset: asset)
    }

    private func generateThumbnails(asset: AVAsset) {
        DispatchQueue.global(qos: .userInitiated).async {
            let gen = AVAssetImageGenerator(asset: asset)
            gen.appliesPreferredTrackTransform = true
            gen.maximumSize = CGSize(width: 120, height: 80)
            var imgs: [UIImage] = []
            for i in 0..<thumbCount {
                let t = CMTime(seconds: Double(i) / Double(thumbCount) * duration, preferredTimescale: 600)
                if let cg = try? gen.copyCGImage(at: t, actualTime: nil) {
                    imgs.append(UIImage(cgImage: cg))
                }
            }
            DispatchQueue.main.async { thumbnails = imgs }
        }
    }

    private func togglePlayback() {
        guard let p = player else { return }
        if p.rate > 0 { p.pause() } else { p.play() }
    }

    private func seekPlayer(to time: Double) {
        player?.pause()
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600),
                     toleranceBefore: .zero, toleranceAfter: .zero)
    }

    // MARK: - 导出

    private func exportClip() {
        isExporting = true
        player?.pause()

        let asset = AVAsset(url: sourceURL)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality) else {
            isExporting = false; onComplete(nil); dismiss(); return
        }

        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("trimmed_\(UUID().uuidString).mp4")
        exporter.outputURL = dest
        exporter.outputFileType = .mp4
        exporter.timeRange = CMTimeRange(
            start: CMTime(seconds: startTime, preferredTimescale: 600),
            end: CMTime(seconds: endTime, preferredTimescale: 600)
        )

        exporter.exportAsynchronously {
            DispatchQueue.main.async {
                isExporting = false
                if exporter.status == .completed {
                    dismiss()
                    onComplete(dest)
                } else {
                    onComplete(nil)
                    dismiss()
                }
            }
        }
    }

    private func formatTime(_ t: Double) -> String {
        let s = Int(t)
        let ms = Int((t - Double(s)) * 10)
        return s < 60 ? "\(s).\(ms)s" : "\(s/60):\(String(format: "%02d", s%60))"
    }
}

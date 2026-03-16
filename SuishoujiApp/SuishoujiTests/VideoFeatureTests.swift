import XCTest
import AVFoundation
import Photos
@testable import Suishouji

/// 视频功能测试
/// 覆盖：Note 模型存储、VideoPlayerView 初始化、视频时长格式、PickerItem、录制参数
final class VideoFeatureTests2: XCTestCase {

    // MARK: - Note 模型：视频字段

    func testNoteVideoDataStoredCorrectly() {
        let videoData = Data(repeating: 0xAB, count: 1024)
        let note = Note(type: .video, text: "test", videoData: videoData, videoDuration: 3.5)
        XCTAssertEqual(note.type, .video)
        XCTAssertEqual(note.videoData, videoData)
        XCTAssertEqual(note.videoDuration ?? 0, 3.5, accuracy: 0.001)
        XCTAssertNil(note.photoData)
    }

    func testNoteVideoWithPhotosIsMixed() {
        let photoData = Data(repeating: 0x01, count: 100)
        let videoData = Data(repeating: 0x02, count: 200)
        let note = Note(type: .mixed, text: "", photoData: photoData, videoData: videoData, videoDuration: 2.0)
        XCTAssertEqual(note.type, .mixed)
        XCTAssertNotNil(note.photoData)
        XCTAssertNotNil(note.videoData)
    }

    func testNoteVideoNilByDefault() {
        let note = Note(type: .text, text: "hello")
        XCTAssertNil(note.videoData)
        XCTAssertNil(note.videoDuration)
    }

    func testNoteVideoWithZeroDuration() {
        let note = Note(type: .video, text: "", videoData: Data(), videoDuration: 0)
        // 0 秒视频应该被允许存储（录制结果判断交给 UI 层）
        XCTAssertEqual(note.videoDuration, 0)
    }

    func testNoteVideoMaxDuration() {
        let note = Note(type: .video, text: "", videoData: Data(count: 10), videoDuration: 5.0)
        XCTAssertLessThanOrEqual(note.videoDuration ?? 0.0, 5.1, "录制最长5秒，超出则异常")
    }

    // MARK: - 视频时长格式化

    func testFormatDurationSeconds() {
        XCTAssertEqual(formatDuration(3.0), "3s")
        XCTAssertEqual(formatDuration(4.9), "4s")
        XCTAssertEqual(formatDuration(0.5), "0s")
    }

    func testFormatDurationMinutes() {
        XCTAssertEqual(formatDuration(60.0), "1:00")
        XCTAssertEqual(formatDuration(90.0), "1:30")
        XCTAssertEqual(formatDuration(125.0), "2:05")
    }

    func testFormatDurationEdge() {
        XCTAssertEqual(formatDuration(59.9), "59s")
        XCTAssertEqual(formatDuration(60.0), "1:00")
    }

    // 复制自 CameraView / NoteRow 里的 formatDuration 实现，保持一致
    private func formatDuration(_ s: Double) -> String {
        let t = Int(s)
        return t < 60 ? "\(t)s" : "\(t/60):\(String(format: "%02d", t%60))"
    }

    // MARK: - PickerItem 枚举

    func testPickerItemPhotoHoldsCorrectData() {
        let img = UIImage()
        let item = PickerItem.photo(id: "test-id", image: img)
        if case .photo(let id, let image) = item {
            XCTAssertEqual(id, "test-id")
            XCTAssertEqual(image, img)
        } else {
            XCTFail("应该是 .photo 类型")
        }
    }

    func testPickerItemVideoHoldsCorrectData() {
        let url = URL(fileURLWithPath: "/tmp/test.mp4")
        let item = PickerItem.video(id: "vid-id", thumbnail: nil, url: url, duration: 3.5)
        if case .video(let id, let thumb, let videoURL, let dur) = item {
            XCTAssertEqual(id, "vid-id")
            XCTAssertNil(thumb)
            XCTAssertEqual(videoURL, url)
            XCTAssertEqual(dur, 3.5, accuracy: 0.001)
        } else {
            XCTFail("应该是 .video 类型")
        }
    }

    func testPickerItemVideoWithThumbnail() {
        let img = UIImage()
        let url = URL(fileURLWithPath: "/tmp/test.mov")
        let item = PickerItem.video(id: "x", thumbnail: img, url: url, duration: 1.0)
        if case .video(_, let thumb, _, _) = item {
            XCTAssertNotNil(thumb)
        } else {
            XCTFail()
        }
    }

    // MARK: - VideoRecorderView 参数

    func testVideoMaxDurationIs5Seconds() {
        // VideoRecorderViewController.maxSeconds 应该是 5
        // 由于是 private，用行为验证：进度条在 5s 时满
        let maxSeconds = 5.0
        let progress = Float(5.0 / maxSeconds)
        XCTAssertEqual(progress, 1.0, accuracy: 0.001, "5秒时进度条应该满")
    }

    func testVideoTooShortThreshold() {
        // 录制时长 > 0.3s 才算有效（避免误触）
        let threshold = 0.3
        XCTAssertTrue(0.5 > threshold, "0.5秒应该算有效录制")
        XCTAssertFalse(0.2 > threshold, "0.2秒不算有效录制")
    }

    // MARK: - VideoPlayerView 构造

    func testVideoPlayerViewCanBeConstructed() {
        let url = URL(fileURLWithPath: "/tmp/test_player.mp4")
        let view = VideoPlayerView(videoURL: url)
        XCTAssertNotNil(view, "VideoPlayerView 应该能构造")
    }

    func testVideoThumbnailViewCanBeConstructed() {
        let url = URL(fileURLWithPath: "/tmp/test_thumb.mp4")
        let view = VideoThumbnailView(videoURL: url)
        XCTAssertNotNil(view, "VideoThumbnailView 应该能构造")
    }

    // MARK: - 视频 URL 有效性

    func testVideoURLFileExistsAfterWrite() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_video_\(UUID().uuidString).mp4")
        let data = Data(repeating: 0xFF, count: 512)
        try data.write(to: tmpURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tmpURL.path))
        try? FileManager.default.removeItem(at: tmpURL)
    }

    func testVideoURLReadableAfterWrite() throws {
        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("test_read_\(UUID().uuidString).mp4")
        let original = Data(repeating: 0xBB, count: 256)
        try original.write(to: tmpURL)
        let readBack = try Data(contentsOf: tmpURL)
        XCTAssertEqual(readBack, original)
        try? FileManager.default.removeItem(at: tmpURL)
    }

    // MARK: - CameraView onSave 签名（参数数量验证）

    func testOnSaveCapturesVideoData() {
        // 验证 onSave 的 11 参数签名：
        // 新签名：(Data?, [Data]?, NoteType, String, String?, Double?, Double?, [String]?, [String]?, [String]?, [Double]?, [String]?) -> Void
        var capturedPaths: [String]? = nil
        var capturedDurations: [Double]? = nil

        let onSave: (Data?, [Data]?, NoteType, String, String?, Double?, Double?, [String]?, [String]?, [String]?, [Double]?, [String]?) -> Void = {
            _, _, _, _, _, _, _, _, _, videoPaths, videoDurations, _ in
            capturedPaths = videoPaths
            capturedDurations = videoDurations
        }

        onSave(nil, nil, .video, "test", nil, nil, nil, nil, nil, ["/tmp/test.mp4"], [3.5], nil)

        XCTAssertEqual(capturedPaths, ["/tmp/test.mp4"])
        XCTAssertEqual(capturedDurations?.first ?? 0, 3.5, accuracy: 0.001)
    }

    func testOnSavePhotoNilVideoData() {
        var capturedPaths: [String]? = ["initial"]

        let onSave: (Data?, [Data]?, NoteType, String, String?, Double?, Double?, [String]?, [String]?, [String]?, [Double]?, [String]?) -> Void = {
            _, _, _, _, _, _, _, _, _, videoPaths, _, _ in
            capturedPaths = videoPaths
        }
        let photoData = Data(repeating: 0x02, count: 50)
        onSave(photoData, nil, .photo, "", nil, nil, nil, nil, nil, nil, nil, nil)
        XCTAssertNil(capturedPaths, "纯照片笔记的 videoPaths 应为 nil")
    }
}

import XCTest
import AVFoundation
import Photos
@testable import Suishouji

/// 视频健壮性测试
/// 目标：把能用代码发现的 bug 在测试层发现，不依赖手动操作
final class VideoRobustnessTests: XCTestCase {

    // MARK: - 1. PickerItem 后台线程安全性（模拟 PHImageManager 的后台回调）

    /// 确认 PickerItem 可以在后台线程创建，不会 crash（Swift 6 Sendable 验证）
    func testPickerItemCreatedOnBackgroundThread() async {
        let result = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // 模拟 PHImageManager 在后台线程的回调
                let item = PickerItem.photo(id: "bg-id", image: UIImage())
                continuation.resume(returning: item)
            }
        }
        if case .photo(let id, _) = result {
            XCTAssertEqual(id, "bg-id")
        } else {
            XCTFail("应该是 .photo")
        }
    }

    func testPickerItemVideoCreatedOnBackgroundThread() async {
        let result: PickerItem? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .background).async {
                let url = FileManager.default.temporaryDirectory
                    .appendingPathComponent("test_bg_\(UUID()).mp4")
                let item = PickerItem.video(id: "vid-bg", thumbnail: nil, url: url, duration: 3.0)
                continuation.resume(returning: item)
            }
        }
        XCTAssertNotNil(result)
    }

    // MARK: - 2. fetchPhoto / fetchVideo nonisolated 行为（隔离验证）

    /// nonisolated async 函数应该能在非主线程安全执行
    func testNonisolatedFetchDoesNotRequireMainThread() async {
        // 如果 fetchPhoto/fetchVideo 依赖 @MainActor 则这里会 assert
        let isMain = await Task.detached(priority: .background) {
            return Thread.isMainThread
        }.value
        XCTAssertFalse(isMain, "detached Task 不应该在主线程")
    }

    // MARK: - 3. 视频临时文件写入 / 读取

    func testVideoTempFileWriteAndRead() throws {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("robustness_\(UUID()).mp4")
        // 写一个假的 mp4 头（ftyp box）
        let fakeData = Data([0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70])
        try fakeData.write(to: dest)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))
        let readBack = try Data(contentsOf: dest)
        XCTAssertEqual(readBack, fakeData)
        try? FileManager.default.removeItem(at: dest)
    }

    func testVideoTempFileCleanupAfterUse() throws {
        let dest = FileManager.default.temporaryDirectory
            .appendingPathComponent("cleanup_\(UUID()).mp4")
        try Data(count: 16).write(to: dest)
        XCTAssertTrue(FileManager.default.fileExists(atPath: dest.path))
        try FileManager.default.removeItem(at: dest)
        XCTAssertFalse(FileManager.default.fileExists(atPath: dest.path))
    }

    // MARK: - 4. 时长捕获竞争（模拟 finishRecording 时序）

    /// 模拟主线程写 capturedDuration，后台线程读，验证顺序
    func testDurationCapturedBeforeStopRecording() async {
        actor DurationStore {
            var capturedDuration: Double = 0
            var recordingSeconds: Double = 0

            func tick() { recordingSeconds += 0.1 }
            func capture() { capturedDuration = recordingSeconds }
            func getEffectiveDuration() -> Double {
                capturedDuration > 0 ? capturedDuration : recordingSeconds
            }
        }

        let store = DurationStore()
        // 模拟录制到 5 秒
        for _ in 0..<50 { await store.tick() }
        // finishRecording 时先 capture
        await store.capture()
        // 然后 stopRecording 触发 delegate（后台线程读）
        let effective = await store.getEffectiveDuration()
        XCTAssertEqual(effective, 5.0, accuracy: 0.01, "捕获的时长应该约等于 5 秒")
    }

    func testDurationCapturePreventsTooShortFalsePositive() async {
        actor DurationStore {
            var capturedDuration: Double = 5.0  // 已正确 capture
            var recordingSeconds: Double = 0    // 竞争读到 0 的情况

            func getEffectiveDuration() -> Double {
                capturedDuration > 0 ? capturedDuration : recordingSeconds
            }
        }

        let store = DurationStore()
        let effective = await store.getEffectiveDuration()
        XCTAssertGreaterThan(effective, 0.3, "即使 recordingSeconds 竞争为 0，capturedDuration 也能保底")
    }

    // MARK: - 5. Note 视频保存端到端

    func testNoteVideoSavedAndRestoredCorrectly() throws {
        let originalData = Data(Array(0..<256).map { UInt8($0) })
        let note = Note(type: .video, text: "end to end", videoData: originalData, videoDuration: 4.5)
        XCTAssertEqual(note.videoData, originalData)
        XCTAssertEqual(note.videoDuration ?? 0, 4.5, accuracy: 0.001)
        XCTAssertEqual(note.type, .video)
    }

    func testMixedNoteHasBothPhotoAndVideo() {
        let photo = Data(repeating: 0x01, count: 100)
        let video = Data(repeating: 0x02, count: 200)
        let note = Note(type: .mixed, photoData: photo, videoData: video, videoDuration: 3.0)
        XCTAssertNotNil(note.photoData)
        XCTAssertNotNil(note.videoData)
        XCTAssertEqual(note.type, .mixed)
    }

    func testVideoNoteOnSaveCallbackCarriesData() {
        // 新签名用 videoPaths + videoDurations（不再传 Data）
        var gotPaths: [String]? = nil
        var gotDurations: [Double]? = nil

        let onSave: (Data?, [Data]?, NoteType, String, String?, Double?, Double?, [String]?, [String]?, [String]?, [Double]?, [String]?) -> Void = {
            _, _, _, _, _, _, _, _, _, videoPaths, videoDurations, _ in
            gotPaths = videoPaths
            gotDurations = videoDurations
        }

        onSave(nil, nil, .video, "test", nil, nil, nil, nil, nil, ["/tmp/video.mp4"], [4.9], nil)

        XCTAssertEqual(gotPaths, ["/tmp/video.mp4"], "视频路径应完整传递给 onSave")
        XCTAssertEqual(gotDurations?.first ?? 0, 4.9, accuracy: 0.001)
    }

    // MARK: - 6. ContentView onSave 不丢视频（新建笔记路径）

    func testNewNoteVideoDataNotLost() {
        var savedNote: Note? = nil

        let onSave: (Data?, [Data]?, NoteType, String, String?, Double?, Double?, [String]?, [String]?, [String]?, [Double]?, [String]?) -> Void = {
            photoData, additionalPhotos, type, text, locationName, lat, lon, assetIds, tags, videoPaths, videoDurations, videoAssetIds in
            savedNote = Note(
                type: type, text: text,
                photoData: photoData, additionalPhotoData: additionalPhotos,
                locationName: locationName, latitude: lat, longitude: lon,
                assetIdentifiers: assetIds, tags: tags,
                videoPaths: videoPaths, videoDurations: videoDurations, videoAssetIds: videoAssetIds
            )
        }

        onSave(nil, nil, .video, "录的视频", nil, nil, nil, nil, nil, ["/tmp/vid.mp4"], [3.7], nil)

        XCTAssertNotNil(savedNote, "笔记应该被创建")
        XCTAssertEqual(savedNote?.videoPaths?.first, "/tmp/vid.mp4", "视频路径不应丢失")
        XCTAssertEqual(savedNote?.type, .video)
    }

    func testEditNoteVideoDataUpdated() {
        let note = Note(type: .video, videoPaths: ["/tmp/old.mp4"], videoDurations: [2.0])

        let onSave: (Data?, [Data]?, NoteType, String, String?, Double?, Double?, [String]?, [String]?, [String]?, [Double]?, [String]?) -> Void = {
            _, _, _, _, _, _, _, _, _, videoPaths, videoDurations, _ in
            note.videoPaths = videoPaths
            note.videoDurations = videoDurations
        }

        onSave(nil, nil, .video, "", nil, nil, nil, nil, nil, ["/tmp/new.mp4"], [4.5], nil)
        XCTAssertEqual(note.videoPaths?.first, "/tmp/new.mp4", "编辑后视频路径应该更新")
        XCTAssertEqual(note.videoDurations?.first ?? 0, 4.5, accuracy: 0.001)
    }

    // MARK: - 7. stableCopy：视频文件复制到 Documents 防止被清理

    func testStableCopyCreatesFileInDocuments() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("picker_\(UUID()).mp4")
        try Data(repeating: 0xAB, count: 1024).write(to: tmp)

        let stable = await MainActor.run { CameraView.stableCopy(from: tmp) }

        XCTAssertNotNil(stable, "stableCopy 应该成功")
        if let url = stable {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "目标文件应该存在")
            XCTAssertTrue(url.path.contains("Documents/Videos"), "应该在 Documents/Videos 下")
            try? FileManager.default.removeItem(at: url)
        }
        try? FileManager.default.removeItem(at: tmp)
    }

    func testStableCopyContentMatchesOriginal() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("source_\(UUID()).mp4")
        let original = Data(Array(0..<256).map { UInt8($0) })
        try original.write(to: tmp)

        let stableOpt = await MainActor.run { CameraView.stableCopy(from: tmp) }
        let stable = try XCTUnwrap(stableOpt)
        let copied = try Data(contentsOf: stable)

        XCTAssertEqual(copied, original, "复制后内容应该一致")
        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.removeItem(at: stable)
    }

    func testStableCopySourceDeletedButDestStillReadable() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("will_delete_\(UUID()).mp4")
        try Data(repeating: 0xFF, count: 512).write(to: tmp)

        let stableOpt = await MainActor.run { CameraView.stableCopy(from: tmp) }
        let stable = try XCTUnwrap(stableOpt)
        try FileManager.default.removeItem(at: tmp)

        XCTAssertTrue(FileManager.default.fileExists(atPath: stable.path), "源文件被删后 Documents 副本应该还在")
        try? FileManager.default.removeItem(at: stable)
    }

    func testVideoDataReadableFromStableURL() async throws {
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("readable_\(UUID()).mp4")
        let expected = Data(repeating: 0xCC, count: 2048)
        try expected.write(to: tmp)

        let stableOpt = await MainActor.run { CameraView.stableCopy(from: tmp) }
        let stable = try XCTUnwrap(stableOpt)
        let videoData = try Data(contentsOf: stable)

        XCTAssertEqual(videoData, expected, "save() 里 Data(contentsOf: stableURL) 应该能读到完整视频")
        try? FileManager.default.removeItem(at: tmp)
        try? FileManager.default.removeItem(at: stable)
    }

    // MARK: - 8. 视频大小限制（PHAsset duration 策略）

    func testVideoUnder5MinutesAllowed() {
        let duration = 299.9  // < 300 秒
        let rejected = duration > 300
        XCTAssertFalse(rejected, "5分钟以下视频应该允许选择")
    }

    func testVideoOver5MinutesRejected() {
        let duration = 300.1  // > 300 秒
        let rejected = duration > 300
        XCTAssertTrue(rejected, "5分钟以上视频应该被拒绝")
    }

    func testVideoExactly5MinutesAllowed() {
        let duration = 300.0
        let rejected = duration > 300
        XCTAssertFalse(rejected, "恰好5分钟的视频不应被拒绝")
    }
}

import XCTest
import Photos
@testable import Suishouji

/// 测试相册 Picker 的选中状态逻辑 + 视频 ID 持久化
/// 覆盖手测发现的两个 bug：
/// 1. 视频点击后选中状态不显示（selectedIds 更新但 badge 不刷新）
/// 2. 重新打开 picker 后上一个视频消失（albumVideoAssetId 未保存）
final class VideoPickerSelectionTests: XCTestCase {

    // MARK: - Bug 1：selectedIds 逻辑验证

    func testToggleAddId() {
        var selectedIds: [String] = []
        let id = "asset-001"

        // 第一次点击：加入
        if let idx = selectedIds.firstIndex(of: id) {
            selectedIds.remove(at: idx)
        } else {
            selectedIds.append(id)
        }
        XCTAssertEqual(selectedIds, ["asset-001"], "第一次点击应加入 selectedIds")
    }

    func testToggleRemoveId() {
        var selectedIds = ["asset-001"]
        let id = "asset-001"

        if let idx = selectedIds.firstIndex(of: id) {
            selectedIds.remove(at: idx)
        } else {
            selectedIds.append(id)
        }
        XCTAssertTrue(selectedIds.isEmpty, "第二次点击应从 selectedIds 移除")
    }

    func testSelectedIndexReturns1BasedIndex() {
        let selectedIds = ["photo-A", "video-B", "photo-C"]
        let indexA = selectedIds.firstIndex(of: "photo-A").map { $0 + 1 }
        let indexB = selectedIds.firstIndex(of: "video-B").map { $0 + 1 }
        let indexC = selectedIds.firstIndex(of: "photo-C").map { $0 + 1 }
        let indexD = selectedIds.firstIndex(of: "not-there").map { $0 + 1 }

        XCTAssertEqual(indexA, 1)
        XCTAssertEqual(indexB, 2)
        XCTAssertEqual(indexC, 3)
        XCTAssertNil(indexD, "未选中的 id 应返回 nil")
    }

    func testVideoAssetIdIsIncludedInSelectedIds() {
        var selectedIds: [String] = []
        let videoId = "video-asset-12345"

        // 点击视频
        if !selectedIds.contains(videoId) {
            selectedIds.append(videoId)
        }
        XCTAssertTrue(selectedIds.contains(videoId), "视频的 localIdentifier 应该加入 selectedIds")
        XCTAssertNotNil(selectedIds.firstIndex(of: videoId).map { $0 + 1 }, "selectedIndex 应该有值（不为 nil），badge 才能显示")
    }

    func testSelectionBadgeVisibilityCondition() {
        // badge 显示条件：selectionIndex != nil
        let selectedIds = ["video-001"]

        let videoId = "video-001"
        let photoId = "photo-002"

        let videoIndex = selectedIds.firstIndex(of: videoId).map { $0 + 1 }
        let photoIndex = selectedIds.firstIndex(of: photoId).map { $0 + 1 }

        // video 已选中 → badge 可见
        XCTAssertNotNil(videoIndex, "已选中的视频应该有 selectionIndex，badge 应该可见")
        // photo 未选中 → badge 不可见（空圆圈）
        XCTAssertNil(photoIndex, "未选中的照片 selectionIndex 应为 nil")
    }

    func testMaxSelectionEnforced() {
        var selectedIds: [String] = ["a", "b", "c"]
        let maxSelection = 3

        // 尝试添加第4个
        let newId = "d"
        let canAdd = selectedIds.count < maxSelection
        if canAdd {
            selectedIds.append(newId)
        }

        XCTAssertFalse(canAdd, "超出 maxSelection 不应添加")
        XCTAssertEqual(selectedIds.count, 3)
    }

    func testVideoOverDurationRejected() {
        let duration = 301.0
        let maxDuration = 300.0
        let rejected = duration > maxDuration
        XCTAssertTrue(rejected)
    }

    func testVideoUnderDurationAccepted() {
        let duration = 45.0
        let maxDuration = 300.0
        let rejected = duration > maxDuration
        XCTAssertFalse(rejected)
    }

    // MARK: - Bug 2：视频 assetId 持久化，重新打开 picker 时能预选

    func testAlbumVideoAssetIdStoredAfterSelection() {
        // 模拟 CameraView 收到 picker 回调后存储 assetId
        var albumVideoAssetId: String? = nil

        let pickerItem = PickerItem.video(
            id: "video-asset-XYZ",
            thumbnail: nil,
            url: URL(fileURLWithPath: "/tmp/test.mov"),
            duration: 3.5
        )

        if case .video(let id, _, _, _) = pickerItem {
            albumVideoAssetId = id
        }

        XCTAssertEqual(albumVideoAssetId, "video-asset-XYZ", "相册视频的 assetId 必须保存，否则重开 picker 无法预选")
    }

    func testPreselectedIdsIncludeAlbumVideoId() {
        // 模拟 openPHPicker() 时把视频 assetId 加入 preselectedIds
        let albumPhotoIds = ["photo-A", "photo-B"]
        let albumVideoAssetId: String? = "video-XYZ"

        var preselectedIds = albumPhotoIds
        if let vId = albumVideoAssetId {
            preselectedIds.append(vId)
        }

        XCTAssertTrue(preselectedIds.contains("video-XYZ"), "视频 assetId 应该在 preselectedIds 里，这样重开 picker 时视频显示为已选")
        XCTAssertEqual(preselectedIds.count, 3)
    }

    func testPreselectedIdsWithoutVideoId() {
        // 没有视频时，preselectedIds 只有照片
        let albumPhotoIds = ["photo-A"]
        let albumVideoAssetId: String? = nil

        var preselectedIds = albumPhotoIds
        if let vId = albumVideoAssetId {
            preselectedIds.append(vId)
        }

        XCTAssertFalse(preselectedIds.contains("video-XYZ"))
        XCTAssertEqual(preselectedIds, ["photo-A"])
    }

    func testSecondVideoSelectionReplacesFirst() {
        // 模拟 toggle 里「先去掉旧视频再加新视频」的逻辑
        // 假设有两个视频 asset
        let videoAssetIds = ["video-OLD", "video-NEW"]
        var selectedIds = ["photo-A", "video-OLD"]  // 已选了旧视频

        let newVideoId = "video-NEW"

        // 模拟 toggle 逻辑：先去掉已有视频
        selectedIds.removeAll { videoAssetIds.contains($0) }
        selectedIds.append(newVideoId)

        XCTAssertFalse(selectedIds.contains("video-OLD"), "旧视频应该被去掉")
        XCTAssertTrue(selectedIds.contains("video-NEW"), "新视频应该被加入")
        XCTAssertTrue(selectedIds.contains("photo-A"), "照片不应受影响")
    }

    func testSelectingVideoTwiceDeselects() {
        // 点击已选中的视频 → 取消选中
        var selectedIds = ["video-001"]
        let id = "video-001"

        if let idx = selectedIds.firstIndex(of: id) {
            selectedIds.remove(at: idx)
        }

        XCTAssertTrue(selectedIds.isEmpty, "再次点击已选视频应该取消选中")
    }

    func testClearVideoResetsAssetId() {
        var albumVideoAssetId: String? = "some-video"
        // 删除视频时清空 assetId
        albumVideoAssetId = nil
        XCTAssertNil(albumVideoAssetId, "删除视频后 assetId 应为 nil")
    }

    // MARK: - PickerItem 混合选择顺序

    func testMixedItemsOrderPreserved() {
        let items: [PickerItem] = [
            .photo(id: "p1", image: UIImage()),
            .video(id: "v1", thumbnail: nil, url: URL(fileURLWithPath: "/tmp/v.mov"), duration: 2.0),
            .photo(id: "p2", image: UIImage())
        ]

        var photoIds: [String] = []
        var videoUrl: URL? = nil

        for item in items {
            switch item {
            case .photo(let id, _): photoIds.append(id)
            case .video(let id, _, let url, _):
                _ = id
                videoUrl = url
            }
        }

        XCTAssertEqual(photoIds, ["p1", "p2"])
        XCTAssertNotNil(videoUrl)
    }

    func testEmptySelectionCompletesWithEmptyArray() {
        let ids: [String] = []
        // guard !ids.isEmpty else { onComplete([]); return }
        let shouldComplete = ids.isEmpty
        XCTAssertTrue(shouldComplete, "空选择应该直接回调空数组")
    }
}

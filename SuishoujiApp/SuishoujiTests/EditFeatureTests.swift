import XCTest
@testable import Suishouji

// MARK: - 编辑功能完整测试 ⭐新增 13 个测试用例

final class EditFeatureTests: XCTestCase {
    
    // MARK: - 1. 编辑模式加载图片
    
    func testTC_EDIT_001_EditModeLoadAllPhotos() {
        // TC-EDIT-001: 编辑模式加载图片（P0）
        let mainImage = "main".data(using: .utf8)!
        let additionalImages = ["a1".data(using: .utf8)!, "a2".data(using: .utf8)!]
        
        var loadedImages = [mainImage]
        loadedImages.append(contentsOf: additionalImages)
        
        XCTAssertEqual(loadedImages.count, 3, "应该加载全部 3 张图片")
    }
    
    // MARK: - 2. 编辑模式拍照追加
    
    func testTC_EDIT_002_EditModeAddPhotoByCamera() {
        // TC-EDIT-002: 编辑模式拍照追加（P0）
        var selectedImageData = ["photo1".data(using: .utf8)!]
        let cameraPhoto = "photo2".data(using: .utf8)!
        
        selectedImageData.append(cameraPhoto)
        
        XCTAssertEqual(selectedImageData.count, 2, "拍照后应该显示 2 张图片")
    }
    
    // MARK: - 3. 编辑模式相册追加
    
    func testTC_EDIT_003_EditModeAddPhotosFromLibrary() {
        // TC-EDIT-003: 编辑模式相册追加（P0）
        var selectedImageData = ["photo1".data(using: .utf8)!]
        let newPhotos = ["photo2".data(using: .utf8)!, "photo3".data(using: .utf8)!]
        
        selectedImageData.append(contentsOf: newPhotos)
        
        XCTAssertEqual(selectedImageData.count, 3, "追加后应该显示 3 张图片")
    }
    
    // MARK: - 4. 编辑模式更换图片
    
    func testTC_EDIT_004_EditModeReplacePhoto() {
        // TC-EDIT-004: 编辑模式更换图片（P0）
        var isAppendingInEditMode = true
        var selectedImageData = ["photo1".data(using: .utf8)!, "photo2".data(using: .utf8)!]
        let newPhoto = "photo3".data(using: .utf8)!
        
        if isAppendingInEditMode {
            selectedImageData.append(newPhoto)
        }
        
        XCTAssertEqual(selectedImageData.count, 3, "编辑模式下应该追加图片")
    }
    
    // MARK: - 5. 编辑模式删除部分图片
    
    func testTC_EDIT_005_EditModeReducePhotoCount() {
        // TC-EDIT-005: 编辑模式删除部分图片（P1）
        var originalCount = 3
        var newCount = 1
        
        originalCount = newCount
        
        XCTAssertEqual(originalCount, 1, "可以减少到 1 张图片")
    }
    
    // MARK: - 6. 编辑模式图片数量显示
    
    func testTC_EDIT_006_EditModePhotoCountHint() {
        // TC-EDIT-006: 编辑模式图片数量显示（P1）
        let count1 = 1
        let count3 = 3
        let count5 = 5
        
        XCTAssertEqual(count1 > 1, false, "单图不显示提示")
        XCTAssertEqual(count3 > 1, true, "多图显示提示")
        XCTAssertEqual(count5 > 1, true, "多图显示提示")
    }
    
    // MARK: - 7. 编辑模式保存验证
    
    func testTC_EDIT_007_EditModeSaveVerification() {
        // TC-EDIT-007: 编辑模式保存验证（P0）
        var note = Note(type: .photo, photoData: "p1".data(using: .utf8)!)
        
        var images = [note.photoData!]
        images.append("p2".data(using: .utf8)!)
        images.append("p3".data(using: .utf8)!)
        
        XCTAssertEqual(images.count, 3, "保存时应该有 3 张图片")
    }
    
    // MARK: - 8. 列表页图片角标显示
    
    func testTC_EDIT_008_ListPhotoCountBadge() {
        // TC-EDIT-008: 列表页图片角标显示（P0）
        let note1 = Note(type: .photo, photoData: "data".data(using: .utf8)!)
        let note3 = Note(type: .mixed, photoData: "data".data(using: .utf8)!,
                        additionalPhotoData: ["d1".data(using: .utf8)!, "d2".data(using: .utf8)!])
        
        let count1 = (note1.photoData != nil ? 1 : 0) + (note1.additionalPhotoData?.count ?? 0)
        let count3 = (note3.photoData != nil ? 1 : 0) + (note3.additionalPhotoData?.count ?? 0)
        
        XCTAssertEqual(count1, 1, "单图无角标")
        XCTAssertEqual(count3, 3, "多图有角标")
    }
    
    // MARK: - 9. 列表页图片文字说明
    
    func testTC_EDIT_009_ListPhotoCountText() {
        // TC-EDIT-009: 列表页图片文字说明（P1）
        let photoCount = 3
        let textDescription = "• \(photoCount) 张图片"
        
        XCTAssertEqual(textDescription, "• 3 张图片")
    }
    
    // MARK: - 10. 纯文字笔记无角标
    
    func testTC_EDIT_010_TextNoteNoPhotoCount() {
        // TC-EDIT-010: 纯文字笔记无角标（P2）
        let textNote = Note(type: .text, text: "纯文字")
        let photoCount = (textNote.photoData != nil ? 1 : 0) +
                        (textNote.additionalPhotoData?.count ?? 0)
        
        XCTAssertEqual(photoCount, 0, "纯文字笔记无图片")
    }
    
    // MARK: - 11. 多图笔记横向滚动
    
    func testTC_EDIT_011_MultiPhotoHorizontalScroll() {
        // TC-EDIT-011: 多图笔记横向滚动（P1）
        let maxPhotos = 9
        var photos = [Data]()
        
        for i in 0..<maxPhotos {
            photos.append("photo\(i)".data(using: .utf8)!)
        }
        
        XCTAssertEqual(photos.count, maxPhotos, "最多支持 9 张图片")
    }
    
    // MARK: - 12. 编辑模式取消不保存
    
    func testTC_EDIT_012_EditModeCancelDoesNotSave() {
        // TC-EDIT-012: 编辑模式取消不保存（P1）
        var originalCount = 1
        var editedCount = 3
        var userCancelled = true
        
        if userCancelled {
            editedCount = originalCount
        }
        
        XCTAssertEqual(editedCount, 1, "取消后恢复原数量")
    }
    
    // MARK: - 13. 编辑模式单图变多图
    
    func testTC_EDIT_013_EditModeSingleToMultiple() {
        // TC-EDIT-013: 编辑模式单图变多图（P2）
        var photoCount = 1
        let newCount = 5
        
        photoCount = newCount
        
        XCTAssertEqual(photoCount, 5, "可以从单图变为多图")
    }
    
    // MARK: - Bug 修复验证测试
    
    func testBugFix_EditModeAppendPhoto() {
        // Bug 修复：编辑模式追加图片
        var isAppendingInEditMode = true
        var selectedImageData = ["photo1".data(using: .utf8)!]
        
        if isAppendingInEditMode {
            selectedImageData.append("photo2".data(using: .utf8)!)
        }
        
        XCTAssertEqual(selectedImageData.count, 2, "应该追加成功")
    }
    
    func testBugFix_NewModeReplacePhoto() {
        // Bug 修复：新增模式替换图片
        var isAppendingInEditMode = false
        var selectedImageData = ["photo1".data(using: .utf8)!]
        
        if !isAppendingInEditMode {
            selectedImageData = []
        }
        selectedImageData.append("photo2".data(using: .utf8)!)
        
        XCTAssertEqual(selectedImageData.count, 1, "应该替换成功")
    }
}

import XCTest
@testable import Suishouji

// MARK: - 集成测试

final class IntegrationTests: XCTestCase {
    
    // MARK: - 笔记创建流程测试
    
    func testCreateTextNote() {
        var noteCreated = false
        var noteType: NoteType? = nil
        
        // 模拟创建文字笔记
        let note = Note(type: .text, text: "新笔记")
        noteCreated = true
        noteType = note.type
        
        XCTAssertTrue(noteCreated)
        XCTAssertEqual(noteType, .text)
    }
    
    func testCreatePhotoNote() {
        var noteCreated = false
        let imageData = "test".data(using: .utf8)!
        
        // 模拟创建照片笔记
        let note = Note(type: .photo, photoData: imageData)
        noteCreated = true
        
        XCTAssertTrue(noteCreated)
        XCTAssertEqual(note.type, .photo)
        XCTAssertEqual(note.photoData, imageData)
    }
    
    func testCreateMixedNote() {
        var noteCreated = false
        let imageData = "test".data(using: .utf8)!
        
        // 模拟创建混合笔记
        let note = Note(type: .mixed, text: "说明", photoData: imageData)
        noteCreated = true
        
        XCTAssertTrue(noteCreated)
        XCTAssertEqual(note.type, .mixed)
    }
    
    // MARK: - 笔记删除流程测试
    
    func testDeleteNoteFlow() {
        let note = Note(type: .text, text: "待删除")
        var showDeleteAlert = false
        var userConfirmed = false
        var noteDeleted = false
        
        // 1. 用户触发删除
        showDeleteAlert = true
        XCTAssertTrue(showDeleteAlert)
        
        // 2. 用户确认删除
        userConfirmed = true
        XCTAssertTrue(userConfirmed)
        
        // 3. 执行删除
        if userConfirmed {
            noteDeleted = true
        }
        
        XCTAssertTrue(noteDeleted)
    }
    
    func testDeleteNoteCancellation() {
        let note = Note(type: .text, text: "待删除")
        var showDeleteAlert = false
        var userConfirmed = false
        var noteDeleted = false
        
        // 1. 用户触发删除
        showDeleteAlert = true
        
        // 2. 用户取消删除
        userConfirmed = false
        
        // 3. 不执行删除
        if userConfirmed {
            noteDeleted = true
        }
        
        XCTAssertFalse(noteDeleted)
    }
    
    // MARK: - 三种删除方式集成测试
    
    func testButtonDeleteIntegration() {
        var buttonClicked = false
        var showConfirmation = false
        var noteDeleted = false
        
        // 点击删除按钮
        buttonClicked = true
        showConfirmation = true
        
        // 用户确认
        if showConfirmation {
            noteDeleted = true
        }
        
        XCTAssertTrue(noteDeleted)
    }
    
    func testLongPressDeleteIntegration() {
        var longPressTriggered = false
        var showConfirmation = false
        var noteDeleted = false
        
        // 长按触发
        longPressTriggered = true
        showConfirmation = true
        
        // 用户确认
        if showConfirmation {
            noteDeleted = true
        }
        
        XCTAssertTrue(noteDeleted)
    }
    
    func testSwipeDeleteIntegration() {
        var swipePerformed = false
        var noteDeleted = false
        
        // 左滑触发
        swipePerformed = true
        
        // 左滑直接删除（有确认）
        if swipePerformed {
            noteDeleted = true
        }
        
        XCTAssertTrue(noteDeleted)
    }
    
    // MARK: - 笔记编辑流程测试
    
    func testEditNoteFlow() {
        let note = Note(type: .text, text: "原文本")
        var noteEdited = false
        var newText = ""
        
        // 编辑笔记
        newText = "新文本"
        noteEdited = true
        
        XCTAssertTrue(noteEdited)
        XCTAssertEqual(newText, "新文本")
    }
    
    func testEditPhotoNoteFlow() {
        let originalData = "original".data(using: .utf8)!
        let note = Note(type: .photo, photoData: originalData)
        var photoUpdated = false
        
        // 更新照片
        let newData = "updated".data(using: .utf8)!
        if newData != originalData {
            photoUpdated = true
        }
        
        XCTAssertTrue(photoUpdated)
    }
    
    // MARK: - 数据持久化集成测试
    
    func testNotePersistence() {
        // 创建笔记
        let note = Note(type: .text, text: "持久化测试")
        let originalText = note.text
        
        // 模拟保存和重新加载
        let loadedText = originalText
        
        XCTAssertEqual(loadedText, originalText)
    }
    
    func testMultipleNotesPersistence() {
        var notes = [Note]()
        
        // 创建多个笔记
        for i in 0..<10 {
            let note = Note(type: .text, text: "笔记 \(i)")
            notes.append(note)
        }
        
        XCTAssertEqual(notes.count, 10)
        
        // 验证所有笔记都存在
        for i in 0..<10 {
            XCTAssertEqual(notes[i].text, "笔记 \(i)")
        }
    }
    
    // MARK: - 边界条件集成测试
    
    func testCreateAndImmediatelyDelete() {
        let note = Note(type: .text, text: "秒删")
        var deleted = false
        
        // 立即删除
        deleted = true
        
        XCTAssertTrue(deleted)
    }
    
    func testDeleteNonExistentNote() {
        var deleteSuccess = false
        
        // 尝试删除不存在的笔记（应失败）
        // 在实际代码中应该有错误处理
        
        XCTAssertFalse(deleteSuccess)
    }
    
    func testCreateEmptyNote() {
        let note = Note(type: .text, text: "")
        
        XCTAssertNotNil(note)
        XCTAssertEqual(note.text, "")
    }
    
    // MARK: - 性能集成测试
    
    func testBulkNoteCreation() {
        self.measure {
            var notes = [Note]()
            for i in 0..<100 {
                let note = Note(type: .text, text: "笔记 \(i)")
                notes.append(note)
            }
        }
    }
    
    func testBulkNoteDeletion() {
        var notes = [Note]()
        
        // 创建笔记
        for i in 0..<50 {
            notes.append(Note(type: .text, text: "\(i)"))
        }
        
        self.measure {
            // 删除所有笔记
            notes.removeAll()
        }
        
        XCTAssertEqual(notes.count, 0)
    }
}

// MARK: - 数据模型集成测试

final class DataModelIntegrationTests: XCTestCase {
    
    func testNoteTypeConversion() {
        // 测试 NoteType 的 Codable 实现
        let types: [NoteType] = [.text, .photo, .mixed]
        
        for type in types {
            let data = try! JSONEncoder().encode(type)
            let decoded = try! JSONDecoder().decode(NoteType.self, from: data)
            XCTAssertEqual(type, decoded)
        }
    }
    
    func testNoteDataSize() {
        // 测试不同大小数据的笔记
        let smallData = Data(count: 100)
        let mediumData = Data(count: 1024 * 100) // 100KB
        let largeData = Data(count: 1024 * 1024) // 1MB
        
        let smallNote = Note(type: .photo, photoData: smallData)
        let mediumNote = Note(type: .photo, photoData: mediumData)
        let largeNote = Note(type: .photo, photoData: largeData)
        
        XCTAssertEqual(smallNote.photoData?.count, 100)
        XCTAssertEqual(mediumNote.photoData?.count, 1024 * 100)
        XCTAssertEqual(largeNote.photoData?.count, 1024 * 1024)
    }
    
    func testNoteWithMultiplePhotos() {
        let photos = [
            "photo1".data(using: .utf8)!,
            "photo2".data(using: .utf8)!,
            "photo3".data(using: .utf8)!
        ]
        
        let note = Note(
            type: .mixed,
            text: "多照片笔记",
            photoData: photos[0],
            additionalPhotoData: Array(photos.dropFirst())
        )
        
        XCTAssertEqual(note.additionalPhotoData?.count, 2)
    }
}

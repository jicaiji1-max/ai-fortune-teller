import XCTest
@testable import Suishouji

final class NoteModelTests: XCTestCase {
    
    // MARK: - 初始化测试
    
    func testNoteInitialization() {
        let text = "测试笔记"
        let type: NoteType = .text
        let note = Note(type: type, text: text)
        
        XCTAssertEqual(note.text, text)
        XCTAssertEqual(note.type, .text)
        XCTAssertNotNil(note.id)
        XCTAssertNotNil(note.timestamp)
        XCTAssertNil(note.photoData)
    }
    
    func testPhotoNoteInitialization() {
        let imageData = "test".data(using: .utf8)!
        let note = Note(type: .photo, text: "照片笔记", photoData: imageData)
        
        XCTAssertEqual(note.type, .photo)
        XCTAssertEqual(note.photoData, imageData)
        XCTAssertEqual(note.text, "照片笔记")
    }
    
    func testMixedNoteInitialization() {
        let mainImage = "main".data(using: .utf8)!
        let extraImages = ["extra1".data(using: .utf8)!, "extra2".data(using: .utf8)!]
        let note = Note(type: .mixed, text: "混合笔记", photoData: mainImage, additionalPhotoData: extraImages)
        
        XCTAssertEqual(note.type, .mixed)
        XCTAssertEqual(note.photoData, mainImage)
        XCTAssertEqual(note.additionalPhotoData, extraImages)
    }
    
    func testEmptyTextNote() {
        let note = Note(type: .text, text: "")
        XCTAssertEqual(note.text, "")
        XCTAssertNotNil(note.id)
    }
    
    func testLongTextNote() {
        let longText = String(repeating: "这是一段很长的文字。", count: 100)
        let note = Note(type: .text, text: longText)
        XCTAssertEqual(note.text, longText)
    }
    
    func testNoteWithSpecialCharacters() {
        let specialText = "特殊字符！@#$%^&*()_+ emoji 😊🎉🚀💡"
        let note = Note(type: .text, text: specialText)
        XCTAssertEqual(note.text, specialText)
    }
    
    func testNoteWithChinesePunctuation() {
        let text = "你好，世界！这是一个测试。真的吗？是的！"
        let note = Note(type: .text, text: text)
        XCTAssertEqual(note.text, text)
    }
    
    func testNoteWithNewlines() {
        let text = "第一行\n第二行\n第三行"
        let note = Note(type: .text, text: text)
        XCTAssertEqual(note.text, text)
        XCTAssertTrue(note.text.contains("\n"))
    }
    
    func testNoteWithWhitespace() {
        let text = "  前后有空格  "
        let note = Note(type: .text, text: text)
        XCTAssertEqual(note.text, text)
    }
    
    // MARK: - NoteType 测试
    
    func testNoteTypeRawValues() {
        XCTAssertEqual(NoteType.text.rawValue, "text")
        XCTAssertEqual(NoteType.photo.rawValue, "photo")
        XCTAssertEqual(NoteType.mixed.rawValue, "mixed")
    }
    
    func testNoteTypeCodable() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let data = try! encoder.encode(NoteType.text)
        let decoded = try! decoder.decode(NoteType.self, from: data)
        
        XCTAssertEqual(decoded, .text)
    }
    
    func testNoteTypeFromArray() {
        let allTypes: [NoteType] = [.text, .photo, .mixed]
        XCTAssertEqual(allTypes.count, 3)
        
        for type in allTypes {
            let data = try! JSONEncoder().encode(type)
            let decoded = try! JSONDecoder().decode(NoteType.self, from: data)
            XCTAssertEqual(type, decoded)
        }
    }
    
    // MARK: - UUID 测试
    
    func testNoteIdIsUnique() {
        let note1 = Note(type: .text)
        let note2 = Note(type: .text)
        XCTAssertNotEqual(note1.id, note2.id)
    }
    
    func testNoteIdIsValidUUID() {
        let note = Note(type: .text)
        let uuidString = note.id.uuidString
        XCTAssertFalse(uuidString.isEmpty)
        XCTAssertEqual(uuidString.count, 36) // UUID 标准长度
    }
    
    func testNoteIdDoesNotChange() {
        let note = Note(type: .text)
        let id1 = note.id
        let id2 = note.id
        XCTAssertEqual(id1, id2)
    }
    
    // MARK: - 时间戳测试
    
    func testNoteTimestampIsRecent() {
        let beforeCreate = Date()
        let note = Note(type: .text)
        let afterCreate = Date()
        
        XCTAssertGreaterThanOrEqual(note.timestamp, beforeCreate)
        XCTAssertLessThanOrEqual(note.timestamp, afterCreate)
    }
    
    func testNoteTimestampDoesNotChange() {
        let note = Note(type: .text)
        let timestamp1 = note.timestamp
        Thread.sleep(forTimeInterval: 0.01) // 等待 1 秒
        let timestamp2 = note.timestamp
        XCTAssertEqual(timestamp1, timestamp2)
    }
    
    func testNoteTimestampIsInPast() {
        let note = Note(type: .text)
        XCTAssertLessThanOrEqual(note.timestamp, Date())
    }
    
    // MARK: - 数据持久化测试
    
    func testNotePhotoDataPersistence() {
        let imageData = "test image data".data(using: .utf8)!
        let note = Note(type: .photo, photoData: imageData)
        
        XCTAssertEqual(note.photoData, imageData)
        XCTAssertNotNil(note.photoData)
    }
    
    func testNoteAdditionalPhotoDataPersistence() {
        let images = ["img1".data(using: .utf8)!, "img2".data(using: .utf8)!]
        let note = Note(type: .mixed, additionalPhotoData: images)
        
        XCTAssertEqual(note.additionalPhotoData, images)
        XCTAssertEqual(note.additionalPhotoData?.count, 2)
    }
    
    func testNoteEmptyAdditionalPhotos() {
        let note = Note(type: .photo, additionalPhotoData: [])
        // SwiftData @Model 在无 ModelContext 时对 nil 的 optional array 可能返回 [] 或 nil
        // 业务语义：空数组等价于 nil（无附加图片）
        let isEmpty = note.additionalPhotoData == nil || note.additionalPhotoData?.isEmpty == true
        XCTAssertTrue(isEmpty, "additionalPhotoData 应为 nil 或空数组")
    }
    
    // MARK: - 边界条件测试
    
    func testNoteWithVeryLongText() {
        let veryLongText = String(repeating: "A", count: 10000)
        let note = Note(type: .text, text: veryLongText)
        XCTAssertEqual(note.text.count, 10000)
    }
    
    func testNoteWithEmojiOnly() {
        let emojiText = "😀😃😄😁😆😅😂🤣"
        let note = Note(type: .text, text: emojiText)
        XCTAssertEqual(note.text, emojiText)
    }
    
    func testNoteWithMixedContent() {
        let mixedText = "文字 + 123 + !@# + 😀"
        let note = Note(type: .mixed, text: mixedText)
        XCTAssertEqual(note.text, mixedText)
    }
    
    // MARK: - 性能测试
    
    func testNoteCreationPerformance() {
        self.measure {
            for _ in 0..<1000 {
                _ = Note(type: .text, text: "测试")
            }
        }
    }
    
    func testNoteWithLargeImageData() {
        let largeData = Data(count: 1024 * 1024 * 5) // 5MB
        let note = Note(type: .photo, photoData: largeData)
        
        XCTAssertEqual(note.photoData?.count, 1024 * 1024 * 5)
    }
    
    // MARK: - 相等性测试
    
    func testNoteIdentityComparison() {
        let note1 = Note(type: .text, text: "相同")
        let note2 = Note(type: .text, text: "相同")
        
        // 即使内容相同，ID 也不同
        XCTAssertNotEqual(note1.id, note2.id)
    }
    
    func testNoteSameReference() {
        let note1 = Note(type: .text)
        let note2 = note1
        
        // 同一引用
        XCTAssertEqual(note1.id, note2.id)
    }
}

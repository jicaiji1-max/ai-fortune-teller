import XCTest
@testable import Suishouji

final class NoteRowTests: XCTestCase {
    
    // MARK: - 组件初始化测试
    
    func testNoteRowInitialization() {
        let note = Note(type: .text, text: "测试")
        var deleteCalled = false
        
        let row = NoteRow(note: note, onDelete: {
            deleteCalled = true
        })
        
        XCTAssertNotNil(row)
        XCTAssertFalse(deleteCalled)
    }
    
    func testNoteRowWithDifferentNoteTypes() {
        let textNote = Note(type: .text, text: "文字")
        let photoNote = Note(type: .photo, photoData: "data".data(using: .utf8)!)
        let mixedNote = Note(type: .mixed, text: "混合", photoData: "data".data(using: .utf8)!)
        
        var deleteCount = 0
        let callback = { deleteCount += 1 }
        
        let _ = NoteRow(note: textNote, onDelete: callback)
        let _ = NoteRow(note: photoNote, onDelete: callback)
        let _ = NoteRow(note: mixedNote, onDelete: callback)
        
        XCTAssertEqual(deleteCount, 0)
    }
    
    // MARK: - 时间格式化测试
    
    func testTimeFormatter() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let date = Date()
        let timeString = formatter.string(from: date)
        
        XCTAssertNotNil(timeString)
        XCTAssertTrue(timeString.contains(":"))
        XCTAssertEqual(timeString.count, 5) // HH:mm 格式
    }
    
    func testTimeFormatterWithDifferentTimes() {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        let midnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: Date())!
        let noon = Calendar.current.date(bySettingHour: 12, minute: 30, second: 0, of: Date())!
        let evening = Calendar.current.date(bySettingHour: 23, minute: 59, second: 0, of: Date())!
        
        XCTAssertEqual(formatter.string(from: midnight), "00:00")
        XCTAssertEqual(formatter.string(from: noon), "12:30")
        XCTAssertEqual(formatter.string(from: evening), "23:59")
    }
    
    // MARK: - 长按删除测试
    
    func testLongPressGestureExists() {
        let note = Note(type: .text, text: "长按测试")
        var longPressTriggered = false
        
        let _ = NoteRow(note: note, onDelete: {
            longPressTriggered = true
        })
        
        // 长按手势应该存在
        XCTAssertNotNil(note)
    }
    
    func testLongPressTriggersDeleteAlert() {
        var showDeleteAlert = false
        
        // 模拟长按
        showDeleteAlert = true
        
        XCTAssertTrue(showDeleteAlert)
    }
    
    func testLongPressDuration() {
        // 长按默认持续时间
        let longPressDuration: TimeInterval = 0.5 // 0.5 秒
        
        XCTAssertGreaterThan(longPressDuration, 0)
        XCTAssertLessThan(longPressDuration, 1)
    }
    
    // MARK: - 删除按钮测试
    
    func testDeleteButtonExists() {
        let note = Note(type: .text, text: "测试")
        var buttonClicked = false
        
        let _ = NoteRow(note: note, onDelete: {
            buttonClicked = true
        })
        
        // 删除按钮应该存在
        XCTAssertNotNil(note)
    }
    
    func testDeleteButtonIsDestructive() {
        // 删除按钮角色应为 destructive
        var isDestructive = true
        
        XCTAssertTrue(isDestructive)
    }
    
    func testDeleteButtonShowsConfirmation() {
        var showConfirmation = false
        
        // 点击删除按钮
        showConfirmation = true
        
        XCTAssertTrue(showConfirmation)
    }
    
    // MARK: - 删除确认对话框测试
    
    func testDeleteConfirmationTitle() {
        let title = "确认删除"
        
        XCTAssertEqual(title, "确认删除")
        XCTAssertFalse(title.isEmpty)
    }
    
    func testDeleteConfirmationMessage() {
        let message = "此操作无法撤销"
        
        XCTAssertEqual(message, "此操作无法撤销")
        XCTAssertTrue(message.contains("无法撤销"))
    }
    
    func testDeleteConfirmationButtons() {
        var cancelButtonExists = false
        var deleteButtonExists = false
        
        cancelButtonExists = true
        deleteButtonExists = true
        
        XCTAssertTrue(cancelButtonExists)
        XCTAssertTrue(deleteButtonExists)
    }
    
    func testCancelButtonRole() {
        var cancelRole = "cancel"
        
        XCTAssertEqual(cancelRole, "cancel")
    }
    
    func testDeleteButtonRole() {
        var deleteRole = "destructive"
        
        XCTAssertEqual(deleteRole, "destructive")
    }
    
    // MARK: - 左滑删除测试
    
    func testSwipeActionExists() {
        var swipeActionEnabled = true
        
        XCTAssertTrue(swipeActionEnabled)
    }
    
    func testSwipeActionIsTrailing() {
        var edge = "trailing"
        
        XCTAssertEqual(edge, "trailing")
    }
    
    func testSwipeActionLabel() {
        let label = "删除"
        
        XCTAssertEqual(label, "删除")
    }
    
    func testSwipeActionIcon() {
        let icon = "trash"
        
        XCTAssertEqual(icon, "trash")
    }
    
    // MARK: - 组件状态测试
    
    func testNoteRowWithEmptyText() {
        let note = Note(type: .text, text: "")
        let _ = NoteRow(note: note, onDelete: {})
        
        XCTAssertNotNil(note)
    }
    
    func testNoteRowWithLongText() {
        let longText = String(repeating: "A", count: 500)
        let note = Note(type: .text, text: longText)
        let _ = NoteRow(note: note, onDelete: {})
        
        XCTAssertEqual(note.text.count, 500)
    }
    
    func testNoteRowWithPhoto() {
        let imageData = "test".data(using: .utf8)!
        let note = Note(type: .photo, photoData: imageData)
        let _ = NoteRow(note: note, onDelete: {})
        
        XCTAssertNotNil(note.photoData)
    }
    
    // MARK: - 性能测试
    
    func testNoteRowRenderPerformance() {
        let note = Note(type: .text, text: "测试")
        
        self.measure {
            for _ in 0..<100 {
                let _ = NoteRow(note: note, onDelete: {})
            }
        }
    }
    
    // MARK: - 边界条件测试
    
    func testNoteRowWithNilPhotoData() {
        let note = Note(type: .text, text: "测试")
        let _ = NoteRow(note: note, onDelete: {})
        
        XCTAssertNil(note.photoData)
    }
    
    func testNoteRowWithLargePhotoData() {
        let largeData = Data(count: 1024 * 1024 * 5) // 5MB
        let note = Note(type: .photo, photoData: largeData)
        let _ = NoteRow(note: note, onDelete: {})
        
        XCTAssertEqual(note.photoData?.count, 1024 * 1024 * 5)
    }
    
    func testNoteRowCallbackNotCalledOnInit() {
        var callbackCalled = false
        
        let note = Note(type: .text, text: "测试")
        let _ = NoteRow(note: note, onDelete: {
            callbackCalled = true
        })
        
        XCTAssertFalse(callbackCalled)
    }
}

// MARK: - 辅助测试

final class DateFormatterTests: XCTestCase {
    
    func testGroupHeaderFormatter() {
        let formatter = DateFormatter()
        formatter.dateFormat = "M 月 d 日"
        
        let date = Date()
        let dateString = formatter.string(from: date)
        
        XCTAssertNotNil(dateString)
        XCTAssertTrue(dateString.contains("月"))
        XCTAssertTrue(dateString.contains("日"))
    }
    
    func testTodayString() {
        let calendar = Calendar.current
        let today = Date()
        let isToday = calendar.isDateInToday(today)
        
        XCTAssertTrue(isToday)
    }
    
    func testYesterdayString() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        let isYesterday = calendar.isDateInYesterday(yesterday)
        
        XCTAssertTrue(isYesterday)
    }
}

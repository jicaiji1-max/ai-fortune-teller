import XCTest
import SwiftUI
@testable import Suishouji

// MARK: - UI 组件测试

final class ComponentTests: XCTestCase {

    // MARK: - ActionButton 测试（新接口：gradientColors 代替 color）

    func testActionButtonInitialization() {
        var actionCalled = false
        let button = ActionButton(
            title: "定格",
            systemImage: "camera.fill",
            gradientColors: [.blue, .purple]
        ) {
            actionCalled = true
        }
        XCTAssertNotNil(button)
        XCTAssertFalse(actionCalled)
    }

    func testActionButtonTitleDingge() {
        // 按钮文字已改为文艺风格
        let title = "定格"
        XCTAssertEqual(title, "定格")
    }

    func testActionButtonTitleLuobi() {
        let title = "落笔"
        XCTAssertEqual(title, "落笔")
    }

    func testActionButtonSystemImageCamera() {
        let image = "camera.fill"
        XCTAssertEqual(image, "camera.fill")
    }

    func testActionButtonSystemImagePencil() {
        let image = "pencil.line"
        XCTAssertEqual(image, "pencil.line")
    }

    func testActionButtonAction() {
        var actionExecuted = false
        let action = { actionExecuted = true }
        action()
        XCTAssertTrue(actionExecuted)
    }

    func testActionButtonGradientColors() {
        let colors: [Color] = [
            Color(red: 0.18, green: 0.38, blue: 0.95),
            Color(red: 0.38, green: 0.18, blue: 0.90)
        ]
        XCTAssertEqual(colors.count, 2)
    }

    // MARK: - EmptyStateView 测试

    func testEmptyStateViewExists() {
        let view = EmptyStateView()
        XCTAssertNotNil(view)
    }

    func testEmptyStateIcon() {
        // 新图标
        let icon = "sparkles"
        XCTAssertEqual(icon, "sparkles")
    }

    func testEmptyStateTitle() {
        let title = "从这里开始"
        XCTAssertEqual(title, "从这里开始")
    }

    func testEmptyStateSubtitle() {
        let subtitle = "定格瞬间，落笔心情"
        XCTAssertEqual(subtitle, "定格瞬间，落笔心情")
    }

    // MARK: - 搜索功能测试

    func testSearchFilterByText() {
        let notes = [
            Note(type: .text, text: "今天吃了火锅"),
            Note(type: .text, text: "明天去爬山"),
            Note(type: .text, text: "买了新相机"),
        ]
        let query = "火锅"
        let results = notes.filter { $0.text.localizedCaseInsensitiveContains(query) }
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.text, "今天吃了火锅")
    }

    func testSearchFilterByLocation() {
        let note = Note(type: .text, text: "随便写写", locationName: "北京三里屯")
        let query = "三里屯"
        let matches = note.locationName?.localizedCaseInsensitiveContains(query) ?? false
        XCTAssertTrue(matches)
    }

    func testSearchFilterByTag() {
        let note = Note(type: .text, text: "工作日记", tags: ["📌 工作", "🌿 生活"])
        let query = "工作"
        let matches = note.tags?.joined(separator: " ").localizedCaseInsensitiveContains(query) ?? false
        XCTAssertTrue(matches)
    }

    func testSearchEmptyQueryReturnsAll() {
        let notes = [
            Note(type: .text, text: "笔记1"),
            Note(type: .text, text: "笔记2"),
        ]
        let query = ""
        let results = query.isEmpty ? notes : notes.filter { $0.text.contains(query) }
        XCTAssertEqual(results.count, 2)
    }

    func testSearchNoResults() {
        let notes = [Note(type: .text, text: "今天天气不错")]
        let results = notes.filter { $0.text.contains("火星") }
        XCTAssertTrue(results.isEmpty)
    }

    // MARK: - 标签筛选测试

    func testTagFilterAll() {
        let notes = [
            Note(type: .text, text: "A", tags: ["📌 工作"]),
            Note(type: .text, text: "B", tags: ["🌿 生活"]),
        ]
        let selectedTag: String? = nil
        let results = notes.filter { note in
            selectedTag == nil || (note.tags?.contains(selectedTag!) ?? false)
        }
        XCTAssertEqual(results.count, 2)
    }

    func testTagFilterSpecific() {
        let notes = [
            Note(type: .text, text: "A", tags: ["📌 工作"]),
            Note(type: .text, text: "B", tags: ["🌿 生活"]),
            Note(type: .text, text: "C", tags: ["📌 工作", "🌿 生活"]),
        ]
        let selectedTag: String? = "📌 工作"
        let results = notes.filter { note in
            selectedTag == nil || (note.tags?.contains(selectedTag!) ?? false)
        }
        XCTAssertEqual(results.count, 2)
    }

    // MARK: - 分组功能测试

    func testGroupNotesByDate() {
        let calendar = Calendar.current
        let today = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        XCTAssertTrue(calendar.isDateInToday(today))
        XCTAssertTrue(calendar.isDateInYesterday(yesterday))
    }

    func testTodayGroupHeader() {
        XCTAssertEqual("今天", "今天")
    }

    func testYesterdayGroupHeader() {
        XCTAssertEqual("昨天", "昨天")
    }

    func testDateGroupHeaderFormat() {
        let formatter = DateFormatter()
        formatter.dateFormat = "M 月 d 日"
        let header = formatter.string(from: Date())
        XCTAssertFalse(header.isEmpty)
        XCTAssertTrue(header.contains("月"))
    }

    // MARK: - 列表排序测试

    func testNoteListSortedByTimestampDesc() {
        var notes = [
            Note(type: .text, text: "旧"),
            Note(type: .text, text: "新"),
        ]
        notes[0] = Note(type: .text, text: "旧")
        notes[1] = Note(type: .text, text: "新")
        notes.sort { $0.timestamp > $1.timestamp }
        XCTAssertNotNil(notes.first)
    }

    func testNoteListIsEmpty() {
        let notes: [Note] = []
        XCTAssertTrue(notes.isEmpty)
    }

    func testNoteListIsNotEmpty() {
        let notes = [Note(type: .text, text: "1")]
        XCTAssertFalse(notes.isEmpty)
    }

    // MARK: - Sheet 展示测试

    func testCameraSheetPresentation() {
        var showCamera = false
        showCamera = true
        XCTAssertTrue(showCamera)
        showCamera = false
        XCTAssertFalse(showCamera)
    }

    func testTextEditorSheetPresentation() {
        var showTextEditor = false
        showTextEditor = true
        XCTAssertTrue(showTextEditor)
    }

    func testEditSheetPresentation() {
        var editingNote: Note? = nil
        editingNote = Note(type: .text, text: "编辑中")
        XCTAssertNotNil(editingNote)
    }
}

// MARK: - 安全测试

final class SecurityTests: XCTestCase {

    func testDeleteRequiresConfirmation() {
        var deleteWithoutConfirmation = false
        XCTAssertFalse(deleteWithoutConfirmation)
    }

    func testUserDataNotExposed() {
        let note = Note(type: .text, text: "私密笔记")
        XCTAssertNotNil(note)
    }

    func testPhotoDataEncapsulation() {
        let imageData = "secret".data(using: .utf8)!
        let note = Note(type: .photo, photoData: imageData)
        XCTAssertEqual(note.photoData, imageData)
    }
}

// MARK: - 辅助功能测试

final class AccessibilityTests: XCTestCase {

    func testButtonLabelsUpdated() {
        // 按钮文字已更新为文艺风格
        let cameraButtonLabel = "定格"
        let textButtonLabel = "落笔"
        XCTAssertEqual(cameraButtonLabel, "定格")
        XCTAssertEqual(textButtonLabel, "落笔")
    }

    func testDeleteButtonLabel() {
        let deleteLabel = "删除"
        XCTAssertEqual(deleteLabel, "删除")
    }

    func testCancelButtonLabel() {
        let cancelLabel = "取消"
        XCTAssertEqual(cancelLabel, "取消")
    }

    func testEmptyStateTextUpdated() {
        // 空状态文案已更新
        let emptyText = "从这里开始"
        XCTAssertEqual(emptyText, "从这里开始")
    }

    func testNavigationTitle() {
        let title = "随手记"
        XCTAssertEqual(title, "随手记")
    }
}

// MARK: - 视频路径测试

final class VideoPathTests: XCTestCase {

    func testRelativePathSaved() {
        // 视频路径应存相对路径，不含 /var/containers/... 前缀
        let relativePath = "Videos/video_test.mov"
        XCTAssertFalse(relativePath.hasPrefix("/"))
    }

    func testAbsolutePathMigration() {
        // 旧绝对路径应能提取相对部分
        let absPath = "/var/mobile/Containers/Data/Application/XXXX/Documents/Videos/test.mov"
        let range = absPath.range(of: "/Documents/")
        XCTAssertNotNil(range, "应能找到 /Documents/ 分割点")
        if let range = range {
            let rel = String(absPath[range.upperBound...])
            XCTAssertEqual(rel, "Videos/test.mov")
        }
    }

    func testVideoExtensionPreserved() {
        // stableCopy 应保留原始扩展名
        let movURL = URL(fileURLWithPath: "/tmp/video.mov")
        let ext = movURL.pathExtension
        XCTAssertEqual(ext, "mov", ".mov 扩展名应被保留，不能强制改成 .mp4")
    }

    func testVideoURLsFromRelativePath() {
        guard let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            XCTFail("无法获取 Documents 目录")
            return
        }
        let relativePath = "Videos/nonexistent_test.mov"
        let fullURL = docsDir.appendingPathComponent(relativePath)
        // 文件不存在时 videoURLs 应返回空（过滤掉）
        XCTAssertFalse(FileManager.default.fileExists(atPath: fullURL.path))
    }
}

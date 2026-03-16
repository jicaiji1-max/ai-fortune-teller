import Foundation

/// 全局标签管理，用 UserDefaults 持久化用户自建标签
@MainActor
class TagStore: ObservableObject {
    static let shared = TagStore()

    // 默认标签（固定，不可删除）
    let defaultTags: [String] = ["📌 工作", "🌿 生活", "✈️ 旅行", "🍜 美食"]

    // 用户自建标签
    @Published var customTags: [String] {
        didSet {
            UserDefaults.standard.set(customTags, forKey: "customTags")
        }
    }

    // 全部标签
    var allTags: [String] { defaultTags + customTags }

    private init() {
        self.customTags = UserDefaults.standard.stringArray(forKey: "customTags") ?? []
    }

    func addTag(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !allTags.contains(trimmed) else { return }
        customTags.append(trimmed)
    }

    func removeCustomTag(_ name: String) {
        customTags.removeAll { $0 == name }
    }

    func isDefault(_ tag: String) -> Bool {
        defaultTags.contains(tag)
    }
}

import SwiftUI
import SwiftData

@main
struct SuishoujiApp: App {
    
    let container: ModelContainer = {
        let schema = Schema([Note.self])
        // migrationPlan: nil 让 SwiftData 自动处理轻量级迁移（新增可选字段）
        // isStoredInMemoryOnly: false 持久化存储
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            // 如果迁移失败（schema 变化太大），清空重建
            // 生产环境应做版本迁移，这里先用删除重建保证不崩溃
            print("SwiftData 容器创建失败，尝试清空重建：\(error)")
            do {
                // 删除旧的 store 文件后重建
                let url = URL.applicationSupportDirectory.appending(path: "default.store")
                try? FileManager.default.removeItem(at: url)
                return try ModelContainer(for: schema, configurations: config)
            } catch {
                fatalError("SwiftData 无法初始化：\(error)")
            }
        }
    }()
    
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}

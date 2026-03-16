import SwiftUI
import SwiftData

@main
struct SuishoujiApp: App {
    
    let container: ModelContainer = {
        let schema = Schema([Note.self])
        let config = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            print("SwiftData 容器创建失败，尝试清空重建：\(error)")
            do {
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

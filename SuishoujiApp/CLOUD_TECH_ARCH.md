# 随手记 App 云同步技术架构方案

> 版本：v1.0 | 日期：2026-03-15 | 作者：claw3（代码助手）

---

## 目录

1. [现有架构分析](#1-现有架构分析)
2. [云端技术选型方案](#2-云端技术选型方案)
3. [登录系统设计](#3-登录系统设计)
4. [数据同步架构](#4-数据同步架构)
5. [中长期技术路线图](#5-中长期技术路线图)
6. [迁移路径](#6-迁移路径)

---

## 1. 现有架构分析

### 1.1 SwiftData 本地存储评估

**优点：**
- ✅ Apple 原生框架，与 SwiftUI 深度集成，声明式 API
- ✅ 零配置，开箱即用，无网络依赖
- ✅ 性能优秀，本地查询极快（<5ms）
- ✅ 自动支持 CoreData 的持久化特性（WAL、原子写入）
- ✅ 隐私安全，数据不离设备

**缺点：**
- ❌ 无原生跨设备同步能力
- ❌ 数据仅存于单设备，换机、丢失即数据丢失
- ❌ 与 CloudKit 集成虽然 Apple 有支持，但限制多（不支持自定义查询、不支持复杂关系）
- ❌ SwiftData 仍较新（iOS 17+），某些边缘 bug 尚存
- ❌ 无法支持多用户协作场景

### 1.2 加入云同步后需改动的关键点

| 改动点 | 影响文件 | 改动说明 |
|--------|---------|---------|
| 数据模型扩展 | `Note.swift` | 加入 UUID、syncStatus、updatedAt、userId 等字段 |
| 网络层新增 | 新增 `SyncManager.swift` | 处理上传/下载/冲突解决 |
| 账号体系 | 新增 `AuthManager.swift` | 处理登录状态、Token 刷新 |
| 图片存储改造 | `SaveToAlbumManager.swift` | 本地缓存 + 云端上传 |
| ContentView | `ContentView.swift` | 加入同步状态 UI（同步指示器、冲突提示） |
| 应用入口 | App 主文件 | 加入 Session 恢复、Token 验证 |

### 1.3 Note.swift 数据模型扩展建议

**当前模型（推测）：**
```swift
@Model
class Note {
    var id: UUID
    var text: String
    var images: [Data]
    var createdAt: Date
    var updatedAt: Date
}
```

**扩展后模型：**
```swift
import SwiftData
import Foundation

@Model
class Note {
    // === 核心字段（现有）===
    var id: UUID = UUID()
    var text: String = ""
    var createdAt: Date = Date()
    var updatedAt: Date = Date()
    
    // === 云同步字段（新增）===
    var serverId: String?           // 服务端主键（String 兼容各种后端）
    var userId: String?             // 归属用户 ID
    var syncStatus: SyncStatus = .pending  // 同步状态
    var syncedAt: Date?             // 最后成功同步时间
    var version: Int = 0            // 乐观锁版本号
    var isDeleted: Bool = false     // 软删除（同步删除时用）
    var deletedAt: Date?            // 删除时间
    
    // === 图片改造（新增）===
    var imageKeys: [String] = []    // 云端存储 Key 列表（替代本地 Data）
    var imageThumbnailKeys: [String] = []  // 缩略图 Key 列表
    var localImagePaths: [String] = []     // 本地缓存路径
    
    // === 元数据（新增）===
    var deviceId: String?           // 最后修改设备 ID
    var tags: [String] = []         // 标签（供将来 AI 分类用）
}

enum SyncStatus: String, Codable {
    case synced     // 已同步
    case pending    // 待同步（本地有修改）
    case conflict   // 冲突待解决
    case failed     // 同步失败
    case uploading  // 上传中
}
```

---

## 2. 云端技术选型方案

### 方案对比矩阵

| 维度 | CloudKit | 自建后端 | Firebase | Supabase |
|------|---------|---------|---------|---------|
| 上手成本 | 低 | 高 | 低 | 中 |
| 运维成本 | 零 | 高 | 低 | 低-中 |
| 免费额度 | 大（iCloud） | 需自付 | 有限制 | 较大 |
| iOS 集成度 | 最高 | 需自写 | 好 | 好 |
| 非Apple端支持 | ❌ | ✅ | ✅ | ✅ |
| 自定义查询 | 受限 | 完全自由 | 受限 | 完全自由 |
| 数据所有权 | Apple | 自己 | Google | 自己 |
| 可扩展性 | 中 | 最高 | 高 | 高 |
| 月费（小规模） | 免费 | $5-20 | 免费-$25 | 免费-$25 |

### 方案A：CloudKit（Apple 原生）

**优点：**
- 与 Apple 账号深度绑定，用户无需注册
- SwiftData + CloudKit 有 `.modelContainer(for:, cloudKitDatabase:)` 一键集成
- 图片存储（CKAsset）免费额度极高（用户 iCloud 空间）
- 合规性最强（GDPR、数据在 Apple 管理）

**缺点：**
- 只支持 Apple 设备（Android/Web 无法访问）
- 无法自定义复杂查询（不支持 JOIN、全文搜索弱）
- CloudKit Dashboard 调试体验差
- 私有数据库无法服务端聚合统计
- 不支持微信等第三方登录（依赖 Apple ID）

**成本：** 几乎免费（用户消耗自己 iCloud 空间）

**适用场景：** 纯 Apple 生态、个人笔记、不需要 Android/Web

```swift
// CloudKit 集成示例（SwiftData + CloudKit）
@main
struct SuishoujiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Note.self, cloudKitDatabase: .automatic)
        // 就这一行，SwiftData 自动同步到 iCloud
    }
}
```

---

### 方案B：自建后端（Node.js/Go + PostgreSQL + S3）

**优点：**
- 完全掌控数据，可无限扩展
- 支持任意平台（iOS/Android/Web/小程序）
- 可实现复杂业务逻辑（AI 标签、搜索、协作）
- 可选择国内服务器（阿里云/腾讯云），符合中国合规

**缺点：**
- 开发工作量大（需写 API、鉴权、同步逻辑）
- 运维负担重（服务器、备份、监控）
- 需要处理所有安全问题

**成本估算（阿里云/腾讯云）：**
- 轻量服务器（2C4G）：~$10-20/月
- RDS PostgreSQL（基础版）：~$15-30/月
- OSS 存储（100GB）：~$2-5/月
- CDN 流量（100GB）：~$5/月
- **总计：~$30-60/月**

**适用场景：** 有后端经验、需要多平台、长期商业化

```go
// Go 后端核心 API 示例
// POST /api/v1/notes/sync
type SyncRequest struct {
    ClientNotes []Note `json:"notes"`
    LastSyncAt  int64  `json:"last_sync_at"`
    DeviceId    string `json:"device_id"`
}

type SyncResponse struct {
    ServerNotes []Note `json:"notes"`     // 服务端有变化的
    Conflicts   []Note `json:"conflicts"` // 冲突列表
    ServerTime  int64  `json:"server_time"`
}
```

---

### 方案C：Firebase（Google）

**优点：
- Firestore 实时同步体验极好
- 多平台 SDK 成熟（iOS/Android/Web）
- Firebase Storage 做图片存储方便
- 国际用户覆盖好

**缺点：**
- 国内访问不稳定（需 VPN 或中转）
- 数据在 Google 服务器，国内合规风险
- Firestore 文档型数据库，复杂查询受限
- 费用可能随用户增长急速上升

**成本：** Spark 计划免费（1GB 存储/5万次读/2万次写/天），Blaze 按量计费

**适用场景：** 面向海外用户、需要实时协作

---

### 方案D：Supabase（开源 Firebase 替代）

**优点：**
- PostgreSQL 原生，支持全文搜索、复杂查询、JSON
- 开源可自托管（完全数据所有权）
- 内置 Auth（支持 Apple/Google/微信等）
- Realtime 订阅基于 PostgreSQL LISTEN/NOTIFY
- Storage 内置（兼容 S3 API）
- 免费额度慷慨（500MB DB、1GB Storage）

**缺点：**
- 相对较新，部分功能不如 Firebase 成熟
- 自托管运维有一定成本
- 国内访问 Supabase Cloud 有延迟

**成本：**
- Supabase Cloud 免费版：适合 MVP
- Pro 版：$25/月（8GB DB、100GB Storage）
- 自托管：只需一台 $10-20/月 的 VPS

**适用场景：** 个人开发者 + 需要灵活性 + 预算有限

```sql
-- Supabase/PostgreSQL 核心表结构示例
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  text TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,           -- 软删除
  is_deleted BOOLEAN DEFAULT FALSE,
  version INT DEFAULT 0,            -- 乐观锁
  device_id TEXT,                   -- 最后修改设备
  tags TEXT[],                      -- 标签数组
  image_keys TEXT[],                -- 图片 Key 列表
  thumbnail_keys TEXT[]             -- 缩略图 Key 列表
);

-- 开启 Row Level Security
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users see own notes" ON notes
  FOR ALL USING (auth.uid() = user_id);

-- 更新时间触发器
CREATE TRIGGER update_notes_updated_at
  BEFORE UPDATE ON notes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
```

---

### 🎯 推荐方案

**推荐：分阶段策略**

**MVP 阶段（0-3月）→ 方案A：CloudKit**
- 理由：零成本、零运维、代码改动最小（一行代码集成）
- 快速验证用户对云同步的需求
- 适合纯 iOS 场景

**成长阶段（3-12月）→ 方案D：Supabase**
- 理由：保留 PostgreSQL 灵活性、支持微信登录、可自托管、成本可控
- 从 CloudKit 迁移时，可以平滑过渡（本地 SwiftData 数据导出后上传）
- 支持未来 Android/Web 扩展

**如果一开始就确定要多平台/商业化 → 直接选方案D（Supabase）**

---

## 3. 登录系统设计

### 3.1 Sign in with Apple（必须支持）

苹果要求：**若 App 支持第三方登录，必须同时支持 Sign in with Apple**

```swift
import AuthenticationServices

class AuthManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    
    // Sign in with Apple
    func signInWithApple() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.performRequests()
    }
}

extension AuthManager: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        
        let userIdentifier = credential.user  // Apple 用户唯一 ID
        let identityToken = credential.identityToken  // JWT，发给服务器验证
        
        // 发给后端验证 Token，获取 App JWT
        Task {
            await sendTokenToServer(identityToken: identityToken, userId: userIdentifier)
        }
    }
}
```

**后端验证 Apple Token：**
```javascript
// Node.js 后端验证
const appleSignIn = require('apple-signin-auth');

async function verifyAppleToken(identityToken) {
    const clientId = 'com.yourcompany.suishouji';
    const payload = await appleSignIn.verifyIdToken(identityToken, {
        audience: clientId,
        ignoreExpiration: false,
    });
    return {
        appleUserId: payload.sub,
        email: payload.email,  // 可能为空（用户可以隐藏）
    };
}
```

### 3.2 微信登录方案

```swift
// 微信登录流程
// 1. 集成微信 SDK (WechatOpenSDK)
// 2. 发起授权
func signInWithWeChat() {
    let req = SendAuthReq()
    req.scope = "snsapi_userinfo"
    req.state = UUID().uuidString
    WXApi.send(req)
}

// 3. AppDelegate 接收回调
func onResp(_ resp: BaseResp) {
    guard let authResp = resp as? SendAuthResp,
          let code = authResp.code else { return }
    // 将 code 发给自己的后端，后端用 code 换取 access_token
    Task { await AuthManager.shared.exchangeWeChatCode(code) }
}
```

**后端微信换 Token：**
```javascript
// 后端用 code 换微信 access_token
async function wechatLogin(code) {
    const res = await fetch(
        `https://api.weixin.qq.com/sns/oauth2/access_token` +
        `?appid=${WECHAT_APP_ID}&secret=${WECHAT_SECRET}` +
        `&code=${code}&grant_type=authorization_code`
    );
    const { access_token, openid } = await res.json();
    
    // 获取用户信息
    const userInfo = await fetch(
        `https://api.weixin.qq.com/sns/userinfo?access_token=${access_token}&openid=${openid}`
    );
    
    // 创建或查找用户，返回 App JWT
    return generateAppJWT({ openid, ...userInfo });
}
```

### 3.3 JWT Token 方案设计

```javascript
// JWT 结构设计
const payload = {
    sub: "user-uuid-xxx",       // 用户 ID（内部）
    provider: "apple",           // 登录方式
    providerUserId: "apple-xxx", // 第三方 ID
    iat: Date.now() / 1000,      // 签发时间
    exp: Date.now() / 1000 + 86400 * 30,  // 30天过期
    deviceId: "device-xxx",      // 设备 ID（可选）
};

// Access Token: 短效（1小时），用于 API 请求
// Refresh Token: 长效（30天），用于刷新 Access Token
```

**Swift 端 Token 管理：**
```swift
class TokenManager {
    private let keychain = Keychain(service: "com.suishouji.tokens")
    
    var accessToken: String? {
        get { keychain["accessToken"] }
        set { keychain["accessToken"] = newValue }
    }
    
    var refreshToken: String? {
        get { keychain["refreshToken"] }
        set { keychain["refreshToken"] = newValue }
    }
    
    // Token 自动刷新（Alamofire Interceptor 模式）
    func refreshIfNeeded() async throws -> String {
        guard let refresh = refreshToken else { throw AuthError.notLoggedIn }
        
        if let access = accessToken, !isExpired(access) {
            return access
        }
        
        // 调用刷新接口
        let newTokens = try await APIClient.shared.refreshToken(refresh)
        accessToken = newTokens.accessToken
        refreshToken = newTokens.refreshToken
        return newTokens.accessToken
    }
}
```

### 3.4 本地账号 → 云账号数据迁移

```swift
class MigrationManager {
    
    /// 触发时机：用户首次登录后
    func migrateLocalDataToCloud(userId: String) async throws {
        let context = ModelContext(sharedModelContainer)
        let localNotes = try context.fetch(FetchDescriptor<Note>())
        
        // 过滤未同步的本地笔记
        let unsynced = localNotes.filter { $0.serverId == nil }
        
        guard !unsynced.isEmpty else { return }
        
        // 显示迁移进度 UI
        await MainActor.run {
            MigrationProgressView.show(total: unsynced.count)
        }
        
        // 批量上传，每批 20 条
        for batch in unsynced.chunked(into: 20) {
            let uploadedNotes = try await APIClient.shared.batchCreateNotes(
                notes: batch.map { NoteDTO(from: $0, userId: userId) }
            )
            
            // 更新本地记录，关联服务端 ID
            for (local, server) in zip(batch, uploadedNotes) {
                local.serverId = server.id
                local.userId = userId
                local.syncStatus = .synced
                local.syncedAt = Date()
            }
        }
        
        try context.save()
        
        // 上传图片（后台任务）
        Task.detached(priority: .background) {
            try await self.migrateLocalImages(unsynced)
        }
    }
    
    private func migrateLocalImages(_ notes: [Note]) async throws {
        for note in notes where !note.localImagePaths.isEmpty {
            for path in note.localImagePaths {
                let imageKey = try await StorageManager.shared.upload(localPath: path)
                note.imageKeys.append(imageKey)
            }
        }
    }
}
```

---

## 4. 数据同步架构

### 4.1 增量同步 vs 全量同步

**推荐：增量同步**

全量同步（每次拉取全部数据）适合数据量极小场景，否则浪费带宽和时间。

**增量同步核心机制：**
```swift
class SyncManager {
    
    /// 增量同步入口
    func sync() async throws {
        let lastSyncAt = UserDefaults.standard.double(forKey: "lastSyncTimestamp")
        
        // 1. 上传本地变更
        try await pushLocalChanges(since: lastSyncAt)
        
        // 2. 拉取服务端变更
        try await pullRemoteChanges(since: lastSyncAt)
        
        // 3. 更新最后同步时间
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastSyncTimestamp")
    }
    
    private func pushLocalChanges(since: TimeInterval) async throws {
        let context = ModelContext(sharedModelContainer)
        let pendingNotes = try context.fetch(
            FetchDescriptor<Note>(
                predicate: #Predicate { $0.syncStatus == .pending || $0.syncStatus == .failed }
            )
        )
        
        guard !pendingNotes.isEmpty else { return }
        
        let dtos = pendingNotes.map { NoteDTO(from: $0) }
        let result = try await APIClient.shared.syncNotes(notes: dtos)
        
        // 处理冲突
        for conflict in result.conflicts {
            try await resolveConflict(conflict)
        }
        
        // 标记已同步
        for note in pendingNotes where !result.conflictIds.contains(note.serverId ?? "") {
            note.syncStatus = .synced
            note.syncedAt = Date()
        }
        try context.save()
    }
    
    private func pullRemoteChanges(since: TimeInterval) async throws {
        let serverNotes = try await APIClient.shared.fetchChanges(since: since)
        let context = ModelContext(sharedModelContainer)
        
        for serverNote in serverNotes {
            // 查找本地对应记录
            let local = try context.fetch(
                FetchDescriptor<Note>(
                    predicate: #Predicate { $0.serverId == serverNote.id }
                )
            ).first
            
            if let local = local {
                // 更新现有记录（服务端版本更新则覆盖）
                if serverNote.version > local.version {
                    local.update(from: serverNote)
                }
            } else {
                // 新增记录
                let newNote = Note(from: serverNote)
                context.insert(newNote)
            }
        }
        try context.save()
    }
}
```

### 4.2 冲突解决策略

**策略对比：**

| 策略 | 原理 | 优点 | 缺点 |
|------|------|------|------|
| LWW（Last-Write-Wins） | 时间戳最新的版本获胜 | 简单易实现 | 可能丢失数据 |
| CRDT | 数学保证无冲突合并 | 完全无损 | 实现复杂 |
| 版本向量（Vector Clock） | 追踪每设备版本 | 精确检测冲突 | 复杂度高 |
| 用户介入 | 提示用户选择 | 最安全 | 体验差 |

**推荐：LWW + 软冲突提示**

对于笔记 App，LWW 是最实用的选择。文字可以用服务端为准（因为笔记改动通常是追加）；图片不可能冲突（只有增删）。

```swift
// 冲突解决实现
func resolveConflict(_ conflict: ConflictInfo) async throws {
    let serverNote = conflict.serverVersion
    let localNote = conflict.localVersion
    
    // 策略：服务端版本 > 本地版本 → 使用服务端
    if serverNote.updatedAt > localNote.updatedAt {
        localNote.update(from: serverNote)
        localNote.syncStatus = .synced
    } else {
        // 本地更新，强制推送到服务端（带版本号防止再次冲突）
        try await APIClient.shared.forceUpdate(note: localNote)
    }
    
    // 严重冲突（两端都在同一时间窗修改）→ 提示用户
    let timeDiff = abs(serverNote.updatedAt.timeIntervalSince(localNote.updatedAt))
    if timeDiff < 5 { // 5秒内同时修改
        await notifyUserOfConflict(conflict)
    }
}
```

### 4.3 离线优先（Offline-First）设计

```swift
// 网络状态监听
import Network

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
}

// ContentView 中的离线优先设计
struct ContentView: View {
    @StateObject private var network = NetworkMonitor()
    @StateObject private var sync = SyncManager()
    
    var body: some View {
        NavigationView {
            NoteListView()
                .overlay(alignment: .top) {
                    if !network.isConnected {
                        OfflineBanner() // 离线提示横幅
                    }
                }
        }
        .onReceive(network.$isConnected) { connected in
            if connected {
                // 网络恢复，触发同步
                Task { try? await sync.sync() }
            }
        }
    }
}

// 操作队列（离线时排队，上线后自动执行）
class OperationQueue {
    // 用 SwiftData 持久化待同步操作，防止 App 重启丢失
    struct PendingOperation {
        let type: OperationType   // create/update/delete
        let noteId: UUID
        let timestamp: Date
    }
    
    enum OperationType: String, Codable {
        case create, update, delete
    }
}
```

### 4.4 图片存储方案

**三级存储架构：**

```
用户操作 → 本地缓存（即时展示）→ 上传 CDN → 删除本地原图（保留缩略图）
```

**图片处理流程：**
```swift
class ImageStorageManager {
    
    /// 上传图片（含压缩和缩略图生成）
    func upload(image: UIImage, noteId: UUID) async throws -> ImageKeys {
        // 1. 压缩原图（最大 2MB）
        let compressed = compress(image, maxBytes: 2 * 1024 * 1024)
        
        // 2. 生成缩略图（200x200，用于列表展示）
        let thumbnail = generateThumbnail(image, size: CGSize(width: 200, height: 200))
        
        // 3. 并行上传
        async let imageKey = uploadToStorage(data: compressed, path: "images/\(noteId)/\(UUID().uuidString).jpg")
        async let thumbKey = uploadToStorage(data: thumbnail, path: "thumbnails/\(noteId)/\(UUID().uuidString).jpg")
        
        return try await ImageKeys(imageKey: imageKey, thumbKey: thumbKey)
    }
    
    private func compress(_ image: UIImage, maxBytes: Int) -> Data {
        var quality: CGFloat = 0.9
        var data = image.jpegData(compressionQuality: quality)!
        
        while data.count > maxBytes && quality > 0.1 {
            quality -= 0.1
            data = image.jpegData(compressionQuality: quality)!
        }
        return data
    }
    
    private func generateThumbnail(_ image: UIImage, size: CGSize) -> Data {
        let renderer = UIGraphicsImageRenderer(size: size)
        let thumb = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        return thumb.jpegData(compressionQuality: 0.7)!
    }
    
    /// 预签名 URL 上传（不经过自己的服务器，直接传 S3/OSS）
    private func uploadToStorage(data: Data, path: String) async throws -> String {
        // 1. 从后端获取预签名上传 URL
        let presignedUrl = try await APIClient.shared.getUploadUrl(path: path)
        
        // 2. 直接 PUT 到 S3/OSS
        var request = URLRequest(url: URL(string: presignedUrl.url)!)
        request.httpMethod = "PUT"
        request.httpBody = data
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw StorageError.uploadFailed
        }
        
        return path  // 返回存储路径作为 Key
    }
}
```

**CDN 配置建议：**
- 国内用户：阿里云 OSS + CDN（成本低、速度快）
- 海外用户：AWS S3 + CloudFront 或 Cloudflare R2（免流量费）
- 图片 URL 格式：`https://cdn.suishouji.com/images/{noteId}/{imageKey}?w=200&q=80`（支持动态裁剪）

---

## 5. 中长期技术路线图

### 短期（0-3个月）：MVP 云同步上线

**目标：** 完成基础云同步，用户数据不再丢失

**里程碑：**
```
Week 1-2: 后端搭建
  - Supabase 项目初始化
  - 数据库 Schema 设计（参考第6节）
  - Sign in with Apple 集成

Week 3-4: iOS 数据层改造
  - Note.swift 模型扩展
  - SyncManager 基础实现（增量同步）
  - 离线队列设计

Week 5-6: 图片同步
  - 图片上传（OSS 预签名 URL）
  - 缩略图生成
  - 本地缓存策略

Week 7-8: 测试 & 上线
  - 88个现有测试用例验证
  - 新增同步相关测试
  - Beta 测试（TestFlight）
  - 迁移脚本测试
```

**交付物：**
- [ ] 用户可用 Apple ID 登录
- [ ] 笔记自动同步到云端
- [ ] 换设备后数据恢复
- [ ] 离线可用（无网络时正常使用，上网后自动同步）

### 中期（3-12个月）：多端支持与性能优化

**里程碑：**
```
Month 4-5: iPad 支持
  - SwiftUI 自适应布局（Adaptive Layout）
  - 分栏视图（NavigationSplitView）
  - Apple Pencil 支持（PencilKit 集成）

Month 6-7: Mac Catalyst / macOS App
  - Mac Catalyst 构建
  - 键盘快捷键支持
  - 菜单栏集成

Month 8-9: 性能优化
  - 图片懒加载 & 预加载
  - 同步性能优化（批量操作）
  - 数据库索引优化

Month 10-12: Web 版本（可选）
  - Next.js Web App
  - 与 Supabase 直连
  - 实时同步（Supabase Realtime）
```

### 长期（1-2年）：协作功能与 AI

**协作功能：**
```swift
// 共享笔记本（Shared Notebook）
@Model
class Notebook {
    var id: UUID
    var name: String
    var ownerId: String
    var members: [Member]
    var notes: [Note]
    var isShared: Bool
}

// 基于 Operational Transform 或 CRDT 的协作编辑
// 推荐使用 Yjs（CRDT 库，有 Swift 绑定）
```

**AI 功能路线：**
```
AI 自动标签：
  - 调用 OpenAI/Claude API 分析笔记内容
  - 自动生成标签（旅行、工作、购物等）

语义搜索：
  - 使用 text-embedding-3-small 生成文本向量
  - Supabase pgvector 扩展存储向量
  - 支持"帮我找上次去北京的笔记"这样的自然语言搜索

OCR 识别：
  - 使用 Vision 框架（本地，iOS 原生）提取图片中的文字
  - 让图片内容也可被搜索

智能整理：
  - 按时间/地点/主题自动分组
  - 每日/每周摘要生成
```

```python
# AI 标签生成示例（后端 Python）
import anthropic

client = anthropic.Anthropic()

async def generate_tags(note_text: str) -> list[str]:
    message = client.messages.create(
        model="claude-3-haiku-20240307",
        max_tokens=100,
        messages=[{
            "role": "user",
            "content": f"为以下笔记生成3-5个中文标签，只返回标签数组JSON：\n{note_text}"
        }]
    )
    return json.loads(message.content[0].text)
```

---

## 6. 迁移路径

### 6.1 数据库 Schema 设计（PostgreSQL/Supabase）

```sql
-- =========================================
-- 用户表（依托 Supabase Auth，补充业务字段）
-- =========================================
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  storage_used BIGINT DEFAULT 0,      -- 已用存储（字节）
  storage_quota BIGINT DEFAULT 1073741824, -- 配额（默认1GB）
  subscription_tier TEXT DEFAULT 'free'   -- free/pro/premium
);

-- =========================================
-- 笔记表（核心）
-- =========================================
CREATE TABLE notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  
  -- 内容
  text TEXT,
  tags TEXT[] DEFAULT '{}',
  
  -- 图片（存储路径，不存 Data）
  image_keys TEXT[] DEFAULT '{}',
  thumbnail_keys TEXT[] DEFAULT '{}',
  image_metadata JSONB DEFAULT '[]',  -- [{key, size, width, height}]
  
  -- 时间戳
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  deleted_at TIMESTAMPTZ,
  
  -- 同步控制
  is_deleted BOOLEAN DEFAULT FALSE,
  version INT DEFAULT 0,             -- 乐观锁
  device_id TEXT,                    -- 最后修改设备
  client_id UUID,                    -- 客户端生成的本地 ID（迁移用）
  
  -- 全文搜索（Postgres 原生）
  search_vector TSVECTOR GENERATED ALWAYS AS (to_tsvector('chinese', coalesce(text,''))) STORED
);

-- 索引
CREATE INDEX idx_notes_user_id ON notes(user_id);
CREATE INDEX idx_notes_updated_at ON notes(user_id, updated_at DESC);
CREATE INDEX idx_notes_deleted ON notes(user_id, is_deleted);
CREATE INDEX idx_notes_search ON notes USING GIN(search_vector);

-- RLS（行级安全）
ALTER TABLE notes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "users_own_notes" ON notes FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- =========================================
-- 设备表（多端同步用）
-- =========================================
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  device_name TEXT,           -- "Cai的iPhone 15 Pro"
  device_model TEXT,          -- "iPhone16,2"
  platform TEXT DEFAULT 'ios', -- ios/ipad/mac/android/web
  push_token TEXT,            -- APNs Token（推送用）
  last_sync_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =========================================
-- 同步日志表（可选，用于 debug）
-- =========================================
CREATE TABLE sync_logs (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id UUID REFERENCES devices(id),
  sync_type TEXT,             -- push/pull/conflict
  notes_pushed INT DEFAULT 0,
  notes_pulled INT DEFAULT 0,
  conflicts INT DEFAULT 0,
  duration_ms INT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### 6.2 API 接口设计（RESTful）

**Base URL：** `https://api.suishouji.app/v1`

```
认证接口
POST   /auth/apple          # Apple Sign In
POST   /auth/wechat         # 微信登录
POST   /auth/refresh        # 刷新 Token
DELETE /auth/session        # 登出

笔记接口
GET    /notes               # 获取笔记列表（支持 ?since=timestamp 增量）
POST   /notes               # 创建笔记
PUT    /notes/:id           # 更新笔记
DELETE /notes/:id           # 软删除笔记
POST   /notes/batch         # 批量创建（迁移用）
POST   /notes/sync          # 双向同步（推荐用这个）

图片接口
POST   /storage/upload-url  # 获取预签名上传 URL
DELETE /storage/:key        # 删除图片

用户接口
GET    /users/me            # 获取个人信息
PUT    /users/me            # 更新个人信息
GET    /users/me/devices    # 设备列表
DELETE /users/me/devices/:id # 解除设备
```

**核心 API 详细设计：**

```typescript
// POST /notes/sync - 双向同步接口（最关键）
// Request
interface SyncRequest {
  clientNotes: NoteDTO[];      // 客户端变更（pending/deleted 的）
  lastSyncAt: number;          // 上次同步时间戳（毫秒）
  deviceId: string;
}

// Response
interface SyncResponse {
  serverNotes: NoteDTO[];      // 服务端变更（lastSyncAt 之后的）
  conflicts: ConflictDTO[];    // 冲突列表
  serverTime: number;          // 服务器当前时间（用于下次同步）
}

interface NoteDTO {
  id: string;                  // 服务端 UUID
  clientId?: string;           // 客户端本地 UUID（新建时携带）
  userId: string;
  text: string;
  imageKeys: string[];
  thumbnailKeys: string[];
  tags: string[];
  version: number;
  createdAt: number;           // 毫秒时间戳
  updatedAt: number;
  deletedAt?: number;
  isDeleted: boolean;
  deviceId: string;
}

interface ConflictDTO {
  clientNote: NoteDTO;
  serverNote: NoteDTO;
  resolution: 'server_wins' | 'client_wins' | 'user_decision';
}
```

```typescript
// 后端同步接口实现（TypeScript/Supabase）
app.post('/v1/notes/sync', authenticate, async (req, res) => {
  const { clientNotes, lastSyncAt, deviceId } = req.body;
  const userId = req.user.id;
  
  // 1. 处理客户端上传的变更
  const conflicts: ConflictDTO[] = [];
  
  for (const clientNote of clientNotes) {
    const { data: serverNote } = await supabase
      .from('notes')
      .select()
      .eq('id', clientNote.id)
      .single();
    
    if (!serverNote) {
      // 新建
      await supabase.from('notes').insert({
        id: clientNote.clientId || clientNote.id,
        user_id: userId,
        ...clientNote,
        version: 1,
      });
    } else if (clientNote.version >= serverNote.version) {
      // 客户端版本更新，直接覆盖
      await supabase.from('notes')
        .update({ ...clientNote, version: serverNote.version + 1 })
        .eq('id', clientNote.id);
    } else {
      // 冲突：客户端版本旧
      conflicts.push({
        clientNote,
        serverNote,
        resolution: serverNote.updated_at > clientNote.updatedAt
          ? 'server_wins'
          : 'client_wins',
      });
    }
  }
  
  // 2. 拉取服务端变更
  const { data: serverChanges } = await supabase
    .from('notes')
    .select()
    .eq('user_id', userId)
    .gt('updated_at', new Date(lastSyncAt).toISOString())
    .order('updated_at', { ascending: true });
  
  res.json({
    serverNotes: serverChanges || [],
    conflicts,
    serverTime: Date.now(),
  });
});
```

### 6.3 平滑迁移策略（现有用户）

**迁移原则：**
1. 用户不感知数据迁移过程
2. 迁移失败不影响使用
3. 支持断点续传

**App 更新时的迁移流程：**

```swift
@main
struct SuishoujiApp: App {
    
    init() {
        Task {
            await MigrationCoordinator.shared.runIfNeeded()
        }
    }
    
    var body: some Scene { ... }
}

class MigrationCoordinator {
    static let shared = MigrationCoordinator()
    
    func runIfNeeded() async {
        let migrationVersion = UserDefaults.standard.integer(forKey: "migrationVersion")
        
        // 迁移 v0 → v1：添加云同步字段
        if migrationVersion < 1 {
            await migrateToV1()
            UserDefaults.standard.set(1, forKey: "migrationVersion")
        }
        
        // 迁移 v1 → v2：图片本地路径 → 云端 Key
        if migrationVersion < 2 {
            // 此步骤在用户登录后才执行
        }
    }
    
    private func migrateToV1() async {
        // SwiftData 会自动处理新字段（有默认值）
        // 只需要确保默认值合理即可
        
        // 为所有本地笔记设置 syncStatus = .pending
        let context = ModelContext(sharedModelContainer)
        let allNotes = try? context.fetch(FetchDescriptor<Note>())
        allNotes?.forEach { note in
            if note.syncStatus == nil {
                note.syncStatus = .pending
            }
        }
        try? context.save()
    }
}
```

**用户引导界面（首次登录）：**
```swift
struct OnboardingCloudSyncView: View {
    @State private var migrationProgress: Double = 0
    @State private var isMigrating = false
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "icloud.and.arrow.up")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("备份你的笔记")
                .font(.title.bold())
            
            Text("登录后，你的所有笔记将自动同步到云端，换设备也不会丢失。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            if isMigrating {
                ProgressView(value: migrationProgress)
                    .progressViewStyle(.linear)
                Text("正在迁移现有笔记... \(Int(migrationProgress * 100))%")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Button("用 Apple 账号登录") {
                    AuthManager.shared.signInWithApple()
                }
                .buttonStyle(.borderedProminent)
                
                Button("暂时跳过") {
                    // 保持纯本地模式
                    dismiss()
                }
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}
```

---

## 附录：技术栈总结

| 层次 | 技术选择 | 说明 |
|------|---------|------|
| iOS 本地存储 | SwiftData | 现有，保留 |
| 云端数据库 | Supabase (PostgreSQL) | 推荐 |
| 云端文件存储 | 阿里云 OSS / Cloudflare R2 | 图片存储 |
| CDN | 阿里云 CDN / Cloudflare | 图片加速 |
| 后端 API | Supabase Edge Functions (Deno) | 轻量 serverless |
| 认证 | Supabase Auth + Apple Sign In | 内置支持 |
| 实时同步 | Supabase Realtime | PostgreSQL LISTEN/NOTIFY |
| 推送通知 | APNs | 同步完成提醒 |
| 监控 | Sentry (iOS) + Supabase Dashboard | 错误追踪 |

---

*文档生成时间：2026-03-15 | 如有疑问请联系 claw3（代码助手）*

import Foundation
import SwiftData

enum NoteType: String, Codable {
    case text
    case photo
    case mixed
    case video
}

@Model
final class Note: Identifiable {
    var id: UUID
    var timestamp: Date
    var type: NoteType
    var text: String
    
    // 位置信息
    var locationName: String?
    var latitude: Double?
    var longitude: Double?
    
    // 图片
    @Attribute(.externalStorage) var photoData: Data?
    @Attribute(.externalStorage) var additionalPhotoData: [Data]?
    var assetIdentifiers: [String]?

    // 标签
    var tags: [String]?

    // 视频：存文件路径（Documents/Videos/xxx.mp4），避免大 Data 进 SwiftData
    // videoPaths[i] 对应 videoDurations[i] 对应 videoAssetIds[i]
    var videoPaths: [String]?
    var videoDurations: [Double]?
    var videoAssetIds: [String]?  // PHAsset localIdentifier，用于编辑时 picker 预选

    // 旧字段兼容（只读，迁移用）
    @Attribute(.externalStorage) var videoData: Data?
    var videoDuration: Double?

    init(type: NoteType, text: String = "",
         photoData: Data? = nil, additionalPhotoData: [Data]? = nil,
         locationName: String? = nil, latitude: Double? = nil, longitude: Double? = nil,
         assetIdentifiers: [String]? = nil, tags: [String]? = nil,
         videoPaths: [String]? = nil, videoDurations: [Double]? = nil, videoAssetIds: [String]? = nil,
         // 兼容旧调用
         videoData: Data? = nil, videoDuration: Double? = nil) {
        self.id = UUID()
        self.timestamp = Date()
        self.type = type
        self.text = text
        self.photoData = photoData
        self.additionalPhotoData = additionalPhotoData?.isEmpty == true ? nil : additionalPhotoData
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.assetIdentifiers = assetIdentifiers
        self.tags = tags
        self.videoPaths = videoPaths
        self.videoDurations = videoDurations
        self.videoAssetIds = videoAssetIds
        self.videoData = videoData
        self.videoDuration = videoDuration
    }

    /// 所有视频的 URL（从 videoPaths 还原，兼容旧 videoData）
    var videoURLs: [URL] {
        let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        var urls: [URL] = []
        if let paths = videoPaths {
            urls = paths.compactMap { path -> URL? in
                // 兼容旧的绝对路径：提取 Documents/ 之后的相对部分重新拼接
                let url: URL
                if path.hasPrefix("/") {
                    // 旧绝对路径 → 提取相对部分
                    if let docs = docsDir,
                       let range = path.range(of: "/Documents/") {
                        let rel = String(path[range.upperBound...])
                        url = docs.appendingPathComponent(rel)
                    } else {
                        url = URL(fileURLWithPath: path)
                    }
                } else {
                    // 新相对路径
                    url = (docsDir ?? URL(fileURLWithPath: "")).appendingPathComponent(path)
                }
                return FileManager.default.fileExists(atPath: url.path) ? url : nil
            }
        }
        // 旧数据迁移：videoData 写临时文件
        if urls.isEmpty, let data = videoData {
            let tmp = FileManager.default.temporaryDirectory
                .appendingPathComponent("legacy_\(id.uuidString).mp4")
            if !FileManager.default.fileExists(atPath: tmp.path) {
                try? data.write(to: tmp)
            }
            urls = [tmp]
        }
        return urls
    }

    var firstVideoURL: URL? { videoURLs.first }

    var allVideoDurations: [Double] {
        if let d = videoDurations, !d.isEmpty { return d }
        if let d = videoDuration { return [d] }
        return []
    }
}

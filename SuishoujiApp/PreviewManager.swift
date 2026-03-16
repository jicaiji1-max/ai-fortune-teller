import UIKit

/// 全局预览状态管理，提升到 ContentView 顶层 overlay，确保全屏显示
@MainActor
class PreviewManager: ObservableObject {
    static let shared = PreviewManager()

    @Published var photoImages: [UIImage] = []
    @Published var photoIndex: Int = 0
    @Published var showPhoto = false

    @Published var videoURLs: [URL] = []
    @Published var videoIndex: Int = 0
    @Published var showVideo = false

    func presentPhotos(_ images: [UIImage], index: Int = 0) {
        photoImages = images
        photoIndex = index
        showPhoto = true
    }

    func presentPhotos(data: [Data], index: Int = 0) {
        photoImages = data.compactMap { UIImage(data: $0) }
        photoIndex = index
        showPhoto = true
    }

    func presentVideos(_ urls: [URL], index: Int = 0) {
        videoURLs = urls
        videoIndex = index
        showVideo = true
    }

    func dismissPhoto() { showPhoto = false }
    func dismissVideo() { showVideo = false }
}

import SwiftUI
import PhotosUI
import UIKit

/// 支持预选（已选图片显示对号）的 PHPicker
/// 回调返回有序数组 [(assetIdentifier, UIImage)]，保留用户选择顺序
/// 注意：preselectedAssetIdentifiers 在 iOS 26 beta 上可能不显示对号（系统 bug）
struct PHPickerView: UIViewControllerRepresentable {
    
    /// 已选的 PHAsset 标识符（用于显示已选状态）
    let preselectedIdentifiers: [String]
    
    /// 还能额外添加的最大图片数量
    let maxAdditional: Int
    
    /// 回调：有序数组 [(assetId, image)]，空数组表示取消
    var onComplete: ([(String, UIImage)]) -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = max(1, preselectedIdentifiers.count + maxAdditional)
        config.filter = .images
        config.selection = .ordered
        if !preselectedIdentifiers.isEmpty {
            config.preselectedAssetIdentifiers = preselectedIdentifiers
        }
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        
        init(_ parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard !results.isEmpty else {
                parent.onComplete([])
                return
            }
            
            let orderedIds = results.map { $0.assetIdentifier ?? "" }
            var loaded = [String: UIImage]()
            let group = DispatchGroup()
            
            for (idx, result) in results.enumerated() {
                let id = orderedIds[idx]
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    if let image = object as? UIImage {
                        loaded[id] = image
                    }
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                let ordered = orderedIds.compactMap { id -> (String, UIImage)? in
                    guard let img = loaded[id] else { return nil }
                    return (id, img)
                }
                self.parent.onComplete(ordered)
            }
        }
    }
}

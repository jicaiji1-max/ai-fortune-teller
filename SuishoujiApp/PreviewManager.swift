import UIKit
import SwiftUI

// MARK: - 预览媒体项（图片或视频）

enum MediaPreviewItem {
    case photo(UIImage)
    case video(URL)
}

// MARK: - 全局预览管理器

@MainActor
class PreviewManager: ObservableObject {
    static let shared = PreviewManager()

    @Published var showPhoto = false
    @Published var showVideo = false

    /// 打开混合媒体预览（图片+视频可以一起左右滑）
    func present(items: [MediaPreviewItem], index: Int = 0) {
        let vc = GalleryViewController(items: items, initialIndex: index, onDismiss: nil)
        presentOnTop(vc)
    }

    func presentPhotos(_ images: [UIImage], index: Int = 0) {
        present(items: images.map { .photo($0) }, index: index)
    }

    func presentPhotos(data: [Data], index: Int = 0) {
        presentPhotos(data.compactMap { UIImage(data: $0) }, index: index)
    }

    func presentVideos(_ urls: [URL], index: Int = 0) {
        present(items: urls.map { .video($0) }, index: index)
    }

    func dismissPhoto() { showPhoto = false }
    func dismissVideo() { showVideo = false }

    private func presentOnTop(_ vc: UIViewController) {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }),
              let root = window.rootViewController else { return }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        top.present(vc, animated: true)
    }
}

// MARK: - 支持下滑关闭的 UIHostingController（视频用）

class SwipeDismissHostingController<Content: View>: UIHostingController<Content> {
    var onDismiss: (() -> Void)?
    private var panDelegate: PanDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let delegate = PanDelegate(vc: self)
        panDelegate = delegate
        let pan = UIPanGestureRecognizer(target: delegate, action: #selector(PanDelegate.handlePan(_:)))
        pan.delegate = delegate
        view.addGestureRecognizer(pan)
    }

    private class PanDelegate: NSObject, UIGestureRecognizerDelegate {
        weak var vc: SwipeDismissHostingController?
        init(vc: SwipeDismissHostingController) { self.vc = vc }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            guard let vc = vc else { return }
            let t = pan.translation(in: vc.view)
            let v = pan.velocity(in: vc.view)
            guard t.y > 0 else { return }
            switch pan.state {
            case .changed:
                vc.view.transform = CGAffineTransform(translationX: 0, y: t.y)
                vc.view.alpha = max(0.4, 1 - t.y / 250)
            case .ended, .cancelled:
                if t.y > 100 || v.y > 700 {
                    UIView.animate(withDuration: 0.18) {
                        vc.view.transform = CGAffineTransform(translationX: 0, y: vc.view.bounds.height)
                        vc.view.alpha = 0
                    } completion: { _ in vc.onDismiss?() }
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) {
                        vc.view.transform = .identity
                        vc.view.alpha = 1
                    }
                }
            default: break
            }
        }

        func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
            guard let pan = gr as? UIPanGestureRecognizer, let vc = vc else { return true }
            let vel = pan.velocity(in: vc.view)
            return vel.y > 0 && abs(vel.y) > abs(vel.x) * 1.5
        }
    }
}

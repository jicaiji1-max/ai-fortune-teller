import SwiftUI
import UIKit

// MARK: - SwiftUI 包装器（overlay 调用入口）

struct PhotoViewerView: UIViewControllerRepresentable {
    let uiImages: [UIImage]
    let initialIndex: Int
    var onDismiss: (() -> Void)?

    init(images: [Data], initialIndex: Int = 0, onDismiss: (() -> Void)? = nil) {
        self.uiImages = images.compactMap { UIImage(data: $0) }
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
    }

    init(uiImages: [UIImage], initialIndex: Int = 0, onDismiss: (() -> Void)? = nil) {
        self.uiImages = uiImages
        self.initialIndex = initialIndex
        self.onDismiss = onDismiss
    }

    func makeUIViewController(context: Context) -> PhotoPageViewController {
        PhotoPageViewController(images: uiImages, initialIndex: initialIndex, onDismiss: onDismiss)
    }

    func updateUIViewController(_ uiViewController: PhotoPageViewController, context: Context) {}
}

// MARK: - 主控制器（UIPageViewController 容器）

class PhotoPageViewController: UIViewController {
    private let images: [UIImage]
    private var currentIndex: Int
    private let onDismiss: (() -> Void)?

    private var pageVC: UIPageViewController!
    private var pageLabel: UILabel?
    private var panStart: CGPoint = .zero

    init(images: [UIImage], initialIndex: Int, onDismiss: (() -> Void)?) {
        self.images = images
        self.currentIndex = max(0, min(initialIndex, max(0, images.count - 1)))
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        // UIPageViewController
        pageVC = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)
        pageVC.dataSource = self
        pageVC.delegate = self
        addChild(pageVC)
        view.addSubview(pageVC.view)
        pageVC.view.frame = view.bounds
        pageVC.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageVC.didMove(toParent: self)

        if !images.isEmpty {
            pageVC.setViewControllers([makeZoomVC(index: currentIndex)], direction: .forward, animated: false)
        }

        // 关闭按钮
        let closeBtn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
        closeBtn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: cfg), for: .normal)
        closeBtn.tintColor = UIColor.white.withAlphaComponent(0.85)
        closeBtn.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(closeBtn)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            closeBtn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeBtn.widthAnchor.constraint(equalToConstant: 44),
            closeBtn.heightAnchor.constraint(equalToConstant: 44),
        ])

        // 页码
        if images.count > 1 {
            let lbl = UILabel()
            lbl.textColor = UIColor.white.withAlphaComponent(0.7)
            lbl.font = .systemFont(ofSize: 13)
            lbl.textAlignment = .center
            view.addSubview(lbl)
            lbl.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                lbl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
                lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ])
            pageLabel = lbl
            updateLabel()
        }

        // 下滑关闭手势
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        view.addGestureRecognizer(pan)
    }

    private func makeZoomVC(index: Int) -> ZoomableImageVC {
        ZoomableImageVC(image: images[index], index: index)
    }

    private func updateLabel() {
        pageLabel?.text = "\(currentIndex + 1) / \(images.count)"
    }

    @objc private func close() { onDismiss?() }

    @objc private func handlePan(_ pan: UIPanGestureRecognizer) {
        let t = pan.translation(in: view)
        let v = pan.velocity(in: view)
        switch pan.state {
        case .changed:
            if t.y > 0 {
                view.transform = CGAffineTransform(translationX: 0, y: t.y)
                view.alpha = max(0.4, 1 - t.y / 250)
            }
        case .ended, .cancelled:
            if t.y > 100 || v.y > 700 {
                UIView.animate(withDuration: 0.18) {
                    self.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                    self.view.alpha = 0
                } completion: { _ in self.onDismiss?() }
            } else {
                UIView.animate(withDuration: 0.18) {
                    self.view.transform = .identity
                    self.view.alpha = 1
                }
            }
        default: break
        }
    }
}

extension PhotoPageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pvc: UIPageViewController, viewControllerBefore vc: UIViewController) -> UIViewController? {
        guard let z = vc as? ZoomableImageVC, z.index > 0 else { return nil }
        return makeZoomVC(index: z.index - 1)
    }
    func pageViewController(_ pvc: UIPageViewController, viewControllerAfter vc: UIViewController) -> UIViewController? {
        guard let z = vc as? ZoomableImageVC, z.index < images.count - 1 else { return nil }
        return makeZoomVC(index: z.index + 1)
    }
}

extension PhotoPageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pvc: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed, let z = pvc.viewControllers?.first as? ZoomableImageVC {
            currentIndex = z.index
            updateLabel()
        }
    }
}

extension PhotoPageViewController: UIGestureRecognizerDelegate {
    // 只在向下滑且主方向是竖向时才接管手势
    func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
        guard let pan = gr as? UIPanGestureRecognizer else { return true }
        let vel = pan.velocity(in: view)
        return vel.y > 0 && abs(vel.y) > abs(vel.x) * 1.5
    }
}

// MARK: - 单页可缩放图片 VC

class ZoomableImageVC: UIViewController, UIScrollViewDelegate {
    let index: Int
    private let image: UIImage

    init(image: UIImage, index: Int) {
        self.image = image
        self.index = index
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let sv = UIScrollView(frame: view.bounds)
        sv.delegate = self
        sv.minimumZoomScale = 1.0
        sv.maximumZoomScale = 5.0
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(sv)

        let iv = UIImageView(image: image)
        iv.contentMode = .scaleAspectFit
        iv.frame = sv.bounds
        iv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        sv.addSubview(iv)

        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        doubleTap.numberOfTapsRequired = 2
        sv.addGestureRecognizer(doubleTap)

        objc_setAssociatedObject(self, &Self.svKey, sv, .OBJC_ASSOCIATION_RETAIN)
        objc_setAssociatedObject(self, &Self.ivKey, iv, .OBJC_ASSOCIATION_RETAIN)
    }

    private static var svKey = 0
    private static var ivKey = 0

    private var scrollView: UIScrollView? { objc_getAssociatedObject(self, &Self.svKey) as? UIScrollView }
    private var imageView: UIImageView? { objc_getAssociatedObject(self, &Self.ivKey) as? UIImageView }

    @objc private func doubleTapped(_ tap: UITapGestureRecognizer) {
        guard let sv = scrollView, let iv = imageView else { return }
        if sv.zoomScale > 1.0 {
            sv.setZoomScale(1.0, animated: true)
        } else {
            let pt = tap.location(in: iv)
            sv.zoom(to: CGRect(x: pt.x - 50, y: pt.y - 50, width: 100, height: 100), animated: true)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
}

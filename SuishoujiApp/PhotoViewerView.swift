import SwiftUI
import UIKit
import AVKit

// MARK: - SwiftUI 包装器（纯图片场景保留兼容）

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

    func makeUIViewController(context: Context) -> GalleryViewController {
        GalleryViewController(items: uiImages.map { .photo($0) }, initialIndex: initialIndex, onDismiss: onDismiss)
    }
    func updateUIViewController(_ vc: GalleryViewController, context: Context) {}
}

// MARK: - 混合媒体画廊 VC（外层分页 ScrollView）

class GalleryViewController: UIViewController {
    private let items: [MediaPreviewItem]
    private var currentIndex: Int
    private let onDismiss: (() -> Void)?

    private var pagingScrollView: UIScrollView!
    private var pageCells: [UIView] = []         // ZoomScrollView 或 VideoCell
    private var players: [Int: AVPlayer] = [:]   // 视频播放器缓存
    private var pageLabel: UILabel?
    private var panDelegate: PanDelegate!

    private let pageGap: CGFloat = 20

    init(items: [MediaPreviewItem], initialIndex: Int, onDismiss: (() -> Void)?) {
        self.items = items
        self.currentIndex = max(0, min(initialIndex, max(0, items.count - 1)))
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupPagingScrollView()
        setupPages()
        setupUI()
        setupPanGesture()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutPages()
        let x = pagingScrollView.bounds.width * CGFloat(currentIndex)
        if abs(pagingScrollView.contentOffset.x - x) > 1 {
            pagingScrollView.setContentOffset(CGPoint(x: x, y: 0), animated: false)
        }
        // 播放当前视频
        playVideo(at: currentIndex)
    }

    private func setupPagingScrollView() {
        let frame = CGRect(x: -pageGap / 2, y: 0,
                           width: view.bounds.width + pageGap, height: view.bounds.height)
        pagingScrollView = UIScrollView(frame: frame)
        pagingScrollView.isPagingEnabled = true
        pagingScrollView.showsHorizontalScrollIndicator = false
        pagingScrollView.showsVerticalScrollIndicator = false
        pagingScrollView.delegate = self
        pagingScrollView.backgroundColor = .black
        pagingScrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(pagingScrollView)
    }

    private func setupPages() {
        for item in items {
            switch item {
            case .photo(let img):
                let zv = ZoomScrollView(image: img)
                pagingScrollView.addSubview(zv)
                pageCells.append(zv)
            case .video:
                let cell = VideoCell()
                pagingScrollView.addSubview(cell)
                pageCells.append(cell)
            }
        }
    }

    private func layoutPages() {
        let w = pagingScrollView.bounds.width
        let h = pagingScrollView.bounds.height
        pagingScrollView.contentSize = CGSize(width: w * CGFloat(items.count), height: h)
        for (i, cell) in pageCells.enumerated() {
            cell.frame = CGRect(x: w * CGFloat(i) + pageGap / 2, y: 0,
                                width: w - pageGap, height: h)
            if let zv = cell as? ZoomScrollView { zv.resetZoom() }
        }
    }

    private func setupUI() {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 28)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: cfg), for: .normal)
        btn.tintColor = .white.withAlphaComponent(0.85)
        btn.addTarget(self, action: #selector(close), for: .touchUpInside)
        view.addSubview(btn)
        btn.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            btn.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            btn.widthAnchor.constraint(equalToConstant: 44),
            btn.heightAnchor.constraint(equalToConstant: 44),
        ])
        if items.count > 1 {
            let lbl = UILabel()
            lbl.textColor = .white.withAlphaComponent(0.7)
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
    }

    private func setupPanGesture() {
        let d = PanDelegate(vc: self)
        panDelegate = d
        let pan = UIPanGestureRecognizer(target: d, action: #selector(PanDelegate.handlePan(_:)))
        pan.delegate = d
        view.addGestureRecognizer(pan)
    }

    private func updateLabel() {
        pageLabel?.text = "\(currentIndex + 1) / \(items.count)"
    }

    @objc private func close() {
        pauseAllVideos()
        dismiss(animated: true) { self.onDismiss?() }
    }

    // MARK: - 视频播放

    private func playVideo(at index: Int) {
        guard index < items.count, case .video(let url) = items[index],
              let cell = pageCells[safe: index] as? VideoCell else { return }
        if players[index] == nil {
            players[index] = AVPlayer(url: url)
        }
        cell.attach(player: players[index]!)
        players[index]?.play()
    }

    private func pauseAllVideos() {
        players.values.forEach { $0.pause() }
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        pauseAllVideos()
    }

    // MARK: - 下滑 delegate

    private class PanDelegate: NSObject, UIGestureRecognizerDelegate {
        weak var vc: GalleryViewController?
        init(vc: GalleryViewController) { self.vc = vc }

        @objc func handlePan(_ pan: UIPanGestureRecognizer) {
            guard let vc = vc else { return }
            let t = pan.translation(in: vc.view)
            let v = pan.velocity(in: vc.view)
            guard t.y > 0 else { return }
            switch pan.state {
            case .changed:
                vc.pagingScrollView.transform = CGAffineTransform(translationX: 0, y: t.y)
                vc.view.alpha = max(0.4, 1 - t.y / 250)
            case .ended, .cancelled:
                if t.y > 100 || v.y > 700 {
                    UIView.animate(withDuration: 0.18) {
                        vc.pagingScrollView.transform = CGAffineTransform(translationX: 0, y: vc.view.bounds.height)
                        vc.view.alpha = 0
                    } completion: { _ in vc.close() }
                } else {
                    UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0) {
                        vc.pagingScrollView.transform = .identity
                        vc.view.alpha = 1
                    }
                }
            default: break
            }
        }

        func gestureRecognizerShouldBegin(_ gr: UIGestureRecognizer) -> Bool {
            guard let pan = gr as? UIPanGestureRecognizer, let vc = vc else { return true }
            let curZoom = (vc.pageCells[safe: vc.currentIndex] as? ZoomScrollView)?.zoomScale ?? 1
            guard curZoom <= 1.0 else { return false }
            let vel = pan.velocity(in: vc.view)
            return vel.y > 0 && abs(vel.y) > abs(vel.x) * 1.5
        }
    }
}

extension GalleryViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        guard page != currentIndex else { return }
        // 暂停上一页视频
        if case .video = items[safe: currentIndex] ?? .photo(UIImage()) {
            players[currentIndex]?.pause()
        }
        currentIndex = page
        updateLabel()
        playVideo(at: currentIndex)
    }
}

// MARK: - 图片缩放 ScrollView

class ZoomScrollView: UIScrollView, UIScrollViewDelegate {
    private let imageView: UIImageView

    init(image: UIImage) {
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        super.init(frame: .zero)
        minimumZoomScale = 1.0
        maximumZoomScale = 5.0
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        isScrollEnabled = false
        backgroundColor = .black
        delegate = self
        addSubview(imageView)

        let dt = UITapGestureRecognizer(target: self, action: #selector(doubleTapped(_:)))
        dt.numberOfTapsRequired = 2
        addGestureRecognizer(dt)
    }
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        if zoomScale <= 1.0 { imageView.frame = bounds; contentSize = bounds.size }
    }

    func resetZoom() { setZoomScale(1.0, animated: false); isScrollEnabled = false }

    @objc private func doubleTapped(_ tap: UITapGestureRecognizer) {
        if zoomScale > 1.0 {
            setZoomScale(1.0, animated: true)
        } else {
            let pt = tap.location(in: imageView)
            zoom(to: CGRect(x: pt.x - 50, y: pt.y - 50, width: 100, height: 100), animated: true)
        }
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        isScrollEnabled = zoomScale > 1.0
        let ox = max((bounds.width - contentSize.width) / 2, 0)
        let oy = max((bounds.height - contentSize.height) / 2, 0)
        imageView.frame = CGRect(x: ox, y: oy, width: contentSize.width, height: contentSize.height)
    }

    func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        isScrollEnabled = scale > 1.0
    }
}

// MARK: - 视频 Cell

class VideoCell: UIView {
    private var playerLayer: AVPlayerLayer?
    private var playerVC: AVPlayerViewController?

    func attach(player: AVPlayer) {
        // 用 AVPlayerViewController embed
        guard playerVC == nil else {
            playerVC?.player = player
            return
        }
        let vc = AVPlayerViewController()
        vc.player = player
        vc.showsPlaybackControls = true
        vc.view.frame = bounds
        vc.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        vc.view.backgroundColor = .black
        addSubview(vc.view)
        playerVC = vc
    }
}

// MARK: - 安全下标

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

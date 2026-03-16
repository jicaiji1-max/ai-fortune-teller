import SwiftUI
import AVFoundation
import Photos

struct VideoRecorderView: UIViewControllerRepresentable {
    // assetId: 视频保存到相册后的 PHAsset localIdentifier（用于 picker 预选）
    var onComplete: (URL?, Double, String?) -> Void

    func makeUIViewController(context: Context) -> VideoRecorderViewController {
        let vc = VideoRecorderViewController()
        vc.onComplete = onComplete
        return vc
    }

    func updateUIViewController(_ uiViewController: VideoRecorderViewController, context: Context) {}
}

class VideoRecorderViewController: UIViewController {
    var onComplete: ((URL?, Double, String?) -> Void)?

    // AVFoundation
    private var captureSession = AVCaptureSession()
    private var videoOutput = AVCaptureMovieFileOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?

    // UI
    private var recordButton = UIButton()
    private var progressView = UIProgressView(progressViewStyle: .bar)
    private var cancelButton = UIButton()
    private var timerLabel = UILabel()
    private var hintLabel = UILabel()

    // 状态机 - 用枚举彻底消除 bool 竞争
    private enum RecordState { case idle, recording, finishing, cancelled, done }
    private var state: RecordState = .idle

    private var recordingTimer: Timer?
    private var tickCount: Int = 0          // 整数计数避免浮点累加误差
    private let maxTicks: Int = 50          // 50 * 0.1s = 精确5秒
    var recordingSeconds: Double { Double(tickCount) * 0.1 }
    private var outputURL: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupCamera()
        setupUI()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }

    // MARK: - Camera Setup

    private func setupCamera() {
        captureSession.sessionPreset = .high
        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let mic = AVCaptureDevice.default(for: .audio)
        else { return }

        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            let audioInput = try AVCaptureDeviceInput(device: mic)
            if captureSession.canAddInput(videoInput)  { captureSession.addInput(videoInput) }
            if captureSession.canAddInput(audioInput)  { captureSession.addInput(audioInput) }
            if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }

            let layer = AVCaptureVideoPreviewLayer(session: captureSession)
            layer.videoGravity = .resizeAspectFill
            layer.frame = view.bounds
            view.layer.insertSublayer(layer, at: 0)
            previewLayer = layer

            DispatchQueue.global(qos: .userInitiated).async { self.captureSession.startRunning() }
        } catch {
            print("[VideoRecorder] setup failed: \(error)")
        }
    }

    // MARK: - UI

    private func setupUI() {
        cancelButton.setTitle("取消", for: .normal)
        cancelButton.setTitleColor(.white, for: .normal)
        cancelButton.titleLabel?.font = .systemFont(ofSize: 17)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20)
        ])

        hintLabel.text = "长按录制 · 最多5秒"
        hintLabel.textColor = .white.withAlphaComponent(0.8)
        hintLabel.font = .systemFont(ofSize: 14)
        hintLabel.textAlignment = .center
        view.addSubview(hintLabel)
        hintLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hintLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -110),
            hintLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        progressView.progressTintColor = UIColor(red: 0.55, green: 0.22, blue: 0.83, alpha: 1)
        progressView.trackTintColor = .white.withAlphaComponent(0.3)
        progressView.progress = 0
        progressView.layer.cornerRadius = 3
        progressView.clipsToBounds = true
        view.addSubview(progressView)
        progressView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            progressView.bottomAnchor.constraint(equalTo: hintLabel.topAnchor, constant: -12),
            progressView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            progressView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            progressView.heightAnchor.constraint(equalToConstant: 6)
        ])

        timerLabel.text = "0.0s"
        timerLabel.textColor = .white
        timerLabel.font = .monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        timerLabel.textAlignment = .center
        timerLabel.isHidden = true
        view.addSubview(timerLabel)
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            timerLabel.bottomAnchor.constraint(equalTo: progressView.topAnchor, constant: -8),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        recordButton.backgroundColor = .white
        recordButton.layer.cornerRadius = 40
        recordButton.layer.borderWidth = 5
        recordButton.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        view.addSubview(recordButton)
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            recordButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80)
        ])

        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPress.minimumPressDuration = 0.2
        recordButton.addGestureRecognizer(longPress)
    }

    // MARK: - Actions

    @objc private func cancelTapped() {
        guard state == .idle || state == .recording else { return }
        state = .cancelled
        recordingTimer?.invalidate()
        recordingTimer = nil
        if videoOutput.isRecording {
            videoOutput.stopRecording()
        } else {
            dismiss(animated: true) { self.onComplete?(nil, 0, nil) }
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            startRecording()
        case .ended, .cancelled, .failed:
            if state == .recording {
                stopAndFinish()
            }
        default: break
        }
    }

    private func startRecording() {
        guard state == .idle else { return }
        state = .recording
        tickCount = 0

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("rec_\(Date().timeIntervalSince1970).mp4")
        outputURL = url
        videoOutput.startRecording(to: url, recordingDelegate: self)

        UIView.animate(withDuration: 0.2) {
            self.recordButton.backgroundColor = UIColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
            self.recordButton.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }
        timerLabel.isHidden = false
        hintLabel.text = "松手停止"

        // 必须用 .common mode，否则长按手势期间 RunLoop 在 .tracking mode，
        // 默认的 .default mode Timer 根本不会触发
        let timer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, self.state == .recording else { return }
            self.tickCount += 1
            let progress = Float(self.tickCount) / Float(self.maxTicks)
            self.progressView.setProgress(progress, animated: true)
            self.timerLabel.text = String(format: "%.1fs / 5s", self.recordingSeconds)
            if self.tickCount >= self.maxTicks {
                self.recordingTimer?.invalidate()
                self.recordingTimer = nil
                self.stopAndFinish()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        recordingTimer = timer
    }

    /// 正常结束录制（松手 or 5秒到）
    private func stopAndFinish() {
        guard state == .recording else { return }
        state = .finishing
        recordingTimer?.invalidate()
        recordingTimer = nil
        // state 已经设为 finishing，delegate 看 state 来判断意图
        videoOutput.stopRecording()
        UIView.animate(withDuration: 0.2) {
            self.recordButton.backgroundColor = .white
            self.recordButton.transform = .identity
        }
        hintLabel.text = "长按录制 · 最多5秒"
    }
}

// MARK: - Delegate

extension VideoRecorderViewController: AVCaptureFileOutputRecordingDelegate {
    nonisolated func fileOutput(_ output: AVCaptureFileOutput,
                                didFinishRecordingTo outputFileURL: URL,
                                from connections: [AVCaptureConnection],
                                error: Error?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            switch self.state {
            case .cancelled:
                self.dismiss(animated: true) { self.onComplete?(nil, 0, nil) }

            case .finishing:
                let seconds = self.recordingSeconds
                if seconds > 0.3 {
                    self.state = .done
                    self.saveToPhotoLibrary(url: outputFileURL) { assetId in
                        self.dismiss(animated: true) {
                            self.onComplete?(outputFileURL, seconds, assetId)
                        }
                    }
                } else {
                    // 录制时间太短，重置让用户重录
                    self.state = .idle
                    self.timerLabel.isHidden = true
                    self.progressView.setProgress(0, animated: false)
                    self.timerLabel.text = "0.0s"
                    self.hintLabel.text = "太短了，再试一次"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        self.hintLabel.text = "长按录制 · 最多5秒"
                    }
                }

            default:
                break
            }
        }
    }

    private func saveToPhotoLibrary(url: URL, completion: @escaping (String?) -> Void) {
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            var placeholder: PHObjectPlaceholder?
            PHPhotoLibrary.shared().performChanges({
                let req = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                placeholder = req?.placeholderForCreatedAsset
            }, completionHandler: { success, _ in
                let assetId = success ? placeholder?.localIdentifier : nil
                DispatchQueue.main.async { completion(assetId) }
            })
        }
    }
}

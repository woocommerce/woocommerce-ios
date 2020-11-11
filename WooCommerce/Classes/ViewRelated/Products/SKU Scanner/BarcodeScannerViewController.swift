import AVFoundation
import UIKit
import Vision

/// Starts live stream video for scanning barcodes.
/// This view controller is meant to be embedded as a child view controller for navigation customization.
final class BarcodeScannerViewController: UIViewController {
    @IBOutlet private weak var videoOutputImageView: UIImageView!

    // Subviews of `videoOutputImageView`.
    private var previewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet private weak var topDimmingView: UIView!
    @IBOutlet private weak var scanAreaView: UIView!
    @IBOutlet private weak var instructionLabel: PaddedLabel!
    @IBOutlet private weak var bottomDimmingView: UIView!

    private let session = AVCaptureSession()
    private var requests = [VNRequest]()

    private lazy var throttler: Throttler = Throttler(seconds: 0.1)

    private let instructionText: String
    private let onBarcodeScanned: (Result<[String], Error>) -> Void

    init(instructionText: String, onBarcodeScanned: @escaping (Result<[String], Error>) -> Void) {
        self.instructionText = instructionText
        self.onBarcodeScanned = onBarcodeScanned
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMainView()
        configureDimmingViews()
        configureScanAreaView()
        configureInstructionLabel()

        configureBarcodeDetection()

        startLiveVideo()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updatePreviewLayerOrientation()
        previewLayer?.frame = videoOutputImageView.bounds
    }
}

extension BarcodeScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    /// Performs Vision request from live video stream.
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // For barcode scanning, it is not necessary to perform detection on each frame. Here we throttle the sampling from the video output.
        throttler.throttle { [weak self] in
            // Access of view frame is required on the main thread.
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }

                let orientation = self.imageOrientationFromDeviceOrientation()
                guard let ciImage = self.imageForBarcodeDetection(from: sampleBuffer, orientation: orientation) else {
                    return
                }

                DispatchQueue.global().async { [weak self] in
                    guard let self = self else { return }

                    // Configures options for `VNImageRequestHandler`.
                    var requestOptions: [VNImageOption: Any] = [:]
                    if let cameraData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
                        requestOptions = [.cameraIntrinsics: cameraData]
                    }

                    let imageRequestHandler = VNImageRequestHandler(ciImage: ciImage, orientation: orientation, options: requestOptions)
                    do {
                        try imageRequestHandler.perform(self.requests)
                    } catch {
                        DDLogError("Error performing barcode detection request: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: Video Processing
//
private extension BarcodeScannerViewController {
    /// Returns a `CIImage` for barcode detection Vision request, if available. This has to be run on the main thread due to frame access.
    /// - Parameters:
    ///   - videoSampleBuffer: sample buffer from video.
    ///   - orientation: expected orientation for the image.
    func imageForBarcodeDetection(from videoSampleBuffer: CMSampleBuffer, orientation: CGImagePropertyOrientation) -> CIImage? {
        // Converts video output sample buffer to a `CIImage`.
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(videoSampleBuffer) else {
            return nil
        }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer).oriented(orientation)

        // Calculates the scan area frame after scaling to the video image size.
        let imageExtent = ciImage.extent
        let scanAreaRect = scanAreaView.frame
        let scaledScanAreaRect = BarcodeScannerFrameScaler.scaling(scanAreaRect, in: videoOutputImageView.frame, to: imageExtent)

        // Crops scan area from the original video output image.
        let croppedCIImage = ciImage.cropped(to: scaledScanAreaRect)
        return croppedCIImage
    }
}

// MARK: Video Setup
//
private extension BarcodeScannerViewController {
    /// Enables and starts live stream video, if available.
    func startLiveVideo() {
        session.sessionPreset = .photo

        guard let captureDevice = AVCaptureDevice.default(for: .video),
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                return
        }

        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        // Sets the quality of the video.
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        // What the camera is seeing.
        session.addInput(deviceInput)
        // What we will display on the screen.
        session.addOutput(deviceOutput)

        // Shows the video as it's being captured.
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        self.previewLayer = previewLayer

        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = videoOutputImageView.bounds
        videoOutputImageView.layer.addSublayer(previewLayer)

        session.startRunning()
    }
}

// MARK: Barcode Detection
//
private extension BarcodeScannerViewController {
    func configureBarcodeDetection() {
        let barcodeRequest = VNDetectBarcodesRequest { [weak self] request, error in
            self?.handleBarcodeDetectionResults(request: request, error: error)
        }
        self.requests = [barcodeRequest]
    }

    func handleBarcodeDetectionResults(request: VNRequest, error: Error?) {
        guard let barcodeObservations = request.results?.compactMap({ $0 as? VNBarcodeObservation }) else {
            return
        }

        let barcodes = barcodeObservations.compactMap { $0.payloadStringValue }.uniqued()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.session.isRunning, barcodes.isNotEmpty else {
                return
            }
            self.onBarcodeScanned(.success(barcodes))
        }
    }
}

// MARK: Configurations
//
private extension BarcodeScannerViewController {
    func configureMainView() {
        view.backgroundColor = .basicBackground
    }

    func configureScanAreaView() {
        scanAreaView.backgroundColor = .clear
    }

    func configureDimmingViews() {
        [topDimmingView, bottomDimmingView].forEach { configureDimmingView($0) }
    }

    func configureDimmingView(_ view: UIView) {
        view.backgroundColor = Constants.dimmingColor
    }

    func configureInstructionLabel() {
        instructionLabel.backgroundColor = Constants.dimmingColor
        instructionLabel.textAlignment = .center
        instructionLabel.applyHeadlineStyle()
        instructionLabel.textColor = .white
        instructionLabel.textInsets = Constants.instructionTextInsets
        instructionLabel.text = instructionText
    }
}

// MARK: Orientation Handling
//
private extension BarcodeScannerViewController {
    func updatePreviewLayerOrientation() {
        if let connection = previewLayer?.connection, connection.isVideoOrientationSupported {
            let orientation = UIApplication.shared.statusBarOrientation
            let videoOrientation: AVCaptureVideoOrientation
            switch orientation {
            case .portrait:
                videoOrientation = .portrait
            case .landscapeRight:
                videoOrientation = .landscapeRight
            case .landscapeLeft:
                videoOrientation = .landscapeLeft
            case .portraitUpsideDown:
                videoOrientation = .portraitUpsideDown
            default:
                videoOrientation = .portrait
            }
            updatePreviewLayerVideoOrientation(connection: connection, orientation: videoOrientation)
        }
    }

    func updatePreviewLayerVideoOrientation(connection: AVCaptureConnection, orientation: AVCaptureVideoOrientation) {
        connection.videoOrientation = orientation
    }
}

private extension BarcodeScannerViewController {
    func imageOrientationFromDeviceOrientation() -> CGImagePropertyOrientation {
        let orientation = UIDevice.current.orientation
        let imageOrientation: CGImagePropertyOrientation
        switch orientation {
        case .portrait:
            imageOrientation = .right
        case .portraitUpsideDown:
            imageOrientation = .left
        case .landscapeLeft:
            imageOrientation = .up
        case .landscapeRight:
            imageOrientation = .down
        case .unknown:
            DDLogWarn("The device orientation is unknown, barcode detection may be affected.")
            fallthrough
        default:
            imageOrientation = .right
        }
        return imageOrientation
    }
}

private extension BarcodeScannerViewController {
    enum Constants {
        static let dimmingColor = UIColor(white: 0.0, alpha: 0.5)
        static let instructionTextInsets = UIEdgeInsets(top: 11, left: 0, bottom: 11, right: 0)
    }
}

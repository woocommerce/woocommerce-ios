import AVFoundation
import UIKit
import Vision

typealias BarcodeSymbology = VNBarcodeSymbology

struct ScannedBarcode: Equatable, Hashable {
    let payloadStringValue: String
    let symbology: BarcodeSymbology
}

/// Format of the code scanning result with a completion handler of the corresponding return type.
enum ScannedCodeFormat {
    case barcode(completion: (Result<[ScannedBarcode], Error>) -> Void)
    case text(recognitionLevel: VNRequestTextRecognitionLevel?, completion: (Result<[String], Error>) -> Void)
}

/// Starts live stream video for scanning codes (barcodes or text codes).
/// This view controller is meant to be embedded as a child view controller for navigation customization.
final class CodeScannerViewController: UIViewController {
    @IBOutlet private weak var videoOutputImageView: UIImageView!

    // Subviews of `videoOutputImageView`.
    private var previewLayer: AVCaptureVideoPreviewLayer?
    @IBOutlet private weak var topDimmingView: UIView!
    @IBOutlet private weak var scanAreaView: UIView!
    @IBOutlet private weak var instructionLabel: PaddedLabel!
    @IBOutlet private weak var bottomDimmingView: UIView!
    @IBOutlet private weak var cancelButton: UIButton!

    // > Delegate any interaction with the AVCaptureSession—including its inputs and outputs—to a
    // > dedicated serial dispatch queue, so that the interaction doesn’t block the main queue.
    // >
    // > – https://developer.apple.com/documentation/avfoundation/capture_setup/avcam_building_a_camera_app
    private let sessionQueue = DispatchQueue(label: "qrlogincamerasession.queue.serial")
    private let session = AVCaptureSession()
    private var requests = [VNRequest]()

    private lazy var throttler: Throttler = Throttler(seconds: 0.1)

    private let instructionText: String
    private let format: ScannedCodeFormat

    init(instructionText: String, format: ScannedCodeFormat) {
        self.instructionText = instructionText
        self.format = format
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

        configureCancelButton()

        startLiveVideo()
    }

    private func configureCancelButton() {
        cancelButton.setTitle(Localization.cancel, for: .normal)
        cancelButton.tintColor = UIColor.white
        cancelButton.addTarget(self, action: #selector(cancelButtonTapped), for: .touchUpInside)
    }

    @objc func cancelButtonTapped() {
        dismiss(animated: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        updatePreviewLayerOrientation()
        previewLayer?.frame = videoOutputImageView.bounds
    }
}

extension CodeScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
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
private extension CodeScannerViewController {
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
private extension CodeScannerViewController {
    /// Enables and starts live stream video, if available.
    func startLiveVideo() {
        session.sessionPreset = .photo
        if #available(iOS 16.0, *) {
            if session.isMultitaskingCameraAccessSupported {
                session.isMultitaskingCameraAccessEnabled = true
            }
        }

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

        sessionQueue.async { [weak self] in
            self?.session.startRunning()
        }
    }
}

// MARK: Barcode Detection
//
private extension CodeScannerViewController {
    func configureBarcodeDetection() {
        let requests: [VNRequest]
        switch format {
            case let .barcode(completion):
                let barcodeRequest = VNDetectBarcodesRequest { [weak self] request, error in
                    self?.handleBarcodeDetectionResults(request: request, error: error, completion: completion)
                }
                requests = [barcodeRequest]
            case let .text(recognitionLevel, completion):
                let textRequest = VNRecognizeTextRequest { [weak self] request, error in
                    self?.handleTextDetectionResults(request: request, error: error, completion: completion)
                }
                if let recognitionLevel {
                    textRequest.recognitionLevel = recognitionLevel
                }
                requests = [textRequest]
        }
        self.requests = requests
    }

    func handleBarcodeDetectionResults(request: VNRequest, error: Error?, completion: @escaping (Result<[ScannedBarcode], Error>) -> Void) {
        guard let barcodeObservations = request.results?.compactMap({ $0 as? VNBarcodeObservation }) else {
            return
        }

        let barcodes: [ScannedBarcode] = barcodeObservations.compactMap {
            guard let payloadStringValue = $0.payloadStringValue else {
                return nil
            }

            return ScannedBarcode(payloadStringValue: payloadStringValue, symbology: $0.symbology)
        }.uniqued()

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard self.session.isRunning, barcodes.isNotEmpty else {
                return
            }
            completion(.success(barcodes))
        }
    }

    func handleTextDetectionResults(request: VNRequest, error: Error?, completion: @escaping (Result<[String], Error>) -> Void) {
        guard let textObservations = request.results?.compactMap({ $0 as? VNRecognizedTextObservation }) else {
            return
        }

        let recognizedStrings = textObservations.compactMap { observation in
            // Returns the string of the top `VNRecognizedText` instance.
            observation.topCandidates(1).first?.string
        }.uniqued()

        DispatchQueue.main.async { [weak self] in
            guard let self, self.session.isRunning, recognizedStrings.isNotEmpty else { return }
            completion(.success(recognizedStrings))
        }
    }
}

// MARK: Configurations
//
private extension CodeScannerViewController {
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
        instructionLabel.numberOfLines = 0
    }
}

// MARK: Orientation Handling
//
private extension CodeScannerViewController {
    func updatePreviewLayerOrientation() {
        if let connection = previewLayer?.connection, connection.isVideoOrientationSupported {
            let orientation = view.window?.windowScene?.interfaceOrientation
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

private extension CodeScannerViewController {
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

private extension CodeScannerViewController {
    enum Constants {
        static let dimmingColor = UIColor(white: 0.0, alpha: 0.5)
        static let instructionTextInsets = UIEdgeInsets(top: 11, left: 0, bottom: 11, right: 0)
    }

    enum Localization {
        static let cancel = NSLocalizedString("Cancel", comment: "Button to dismiss the screen")
    }
}

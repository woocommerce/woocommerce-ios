import AVFoundation
import UIKit
import Vision
import Yosemite

enum BoxAnchorLocation {
    case bottomLeft
    case topLeft
    case topRight
    case bottomRight
    case none
}

final class InventoryScannerViewController: UIViewController {
    @IBOutlet private weak var videoOutputImageView: UIImageView!

    private let textBoxSize: CGSize = CGSize(width: 200.0, height: 200.0)
    private let contentFormatting: [NSAttributedString.Key: Any] = [
        .foregroundColor : UIColor.black,
        .font : UIFont.systemFont(ofSize: 18.0, weight: .medium)
    ]

    private var session = AVCaptureSession()
    private var requests = [VNRequest]()

    private var totalNumberOfTextBoxes: Int = 0

    private lazy var resultsNavigationController: InventoryScannerResultsNavigationController = InventoryScannerResultsNavigationController()

    private lazy var throttler: Throttler = Throttler(seconds: 0.5)

    private let siteID: Int64

    init(siteID: Int64) {
        self.siteID = siteID
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavigation()
        startLiveVideo()
    }

    override func viewWillAppear(_ animated: Bool) {
        startBarcodeDetection()
    }

    override func viewDidLayoutSubviews() {
        self.videoOutputImageView.layer.sublayers?[0].frame = videoOutputImageView.bounds
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func startLiveVideo() {
        // Enable live stream video
        session.sessionPreset = AVCaptureSession.Preset.photo

        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video),
            let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
                return
        }

        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        // Set the quality of the video
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        // What the camera is seeing
        session.addInput(deviceInput)
        // What we will display on the screen
        session.addOutput(deviceOutput)

        // TODO-jc: update orientation; support rotation
        // Show the video as it's being captured
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        let deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation
        // Orientation is reversed
        switch (deviceOrientation) {
        case .landscapeLeft:
            previewLayer.connection?.videoOrientation = .landscapeRight
        case .landscapeRight:
            previewLayer.connection?.videoOrientation = .landscapeLeft
        case .portrait:
            previewLayer.connection?.videoOrientation = .portrait
        case .portraitUpsideDown:
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
        default:
            previewLayer.connection?.videoOrientation = .landscapeRight
        }
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = videoOutputImageView.bounds
        videoOutputImageView.layer.addSublayer(previewLayer)

        session.startRunning()
    }

    func startBarcodeDetection() {
        let barcodeRequest = VNDetectBarcodesRequest(completionHandler: detectBarcodeHandler)
        print("!! \(VNDetectBarcodesRequest.supportedSymbologies)")
        self.requests = [barcodeRequest]
    }

    // TODO-jc: remove?
    @IBAction func handleVideoTapGesture(recognizer: UITapGestureRecognizer) {
        let touchPoint: CGPoint = recognizer.location(in: videoOutputImageView)
        let sublayers: [CALayer] = videoOutputImageView.layer.sublayers!
        let textBoxLayers: [CALayer] = Array(sublayers[(sublayers.count - totalNumberOfTextBoxes)...])

        for textBox in textBoxLayers {
            if textBox.frame.contains(touchPoint) {
                if session.isRunning {
                    session.stopRunning()
                }
                return
            }
        }

        toggleSession()
    }

    // TODO-jc: remove?
    func toggleSession() {
        if session.isRunning {
            session.stopRunning()
        } else {
            session.startRunning()
        }
    }

    // Handles barcode detection requests
    func detectBarcodeHandler(request: VNRequest, error: Error?) {
        if let error = error {
            print(error)
        }
        guard let barcodes = request.results, barcodes.isNotEmpty else {
            return
        }

        // Perform UI updates on the main thread
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }

            guard self.session.isRunning else {
                return
            }

            self.videoOutputImageView.layer.sublayers?.removeSubrange(1...)
            self.totalNumberOfTextBoxes = 0

            // This will be used to eliminate duplicate findings
            var barcodeObservations: [String: VNBarcodeObservation] = [:]
            for barcode in barcodes.compactMap({ $0 as? VNBarcodeObservation }) {
                guard let barcodeString = barcode.payloadStringValue else {
                    continue
                }

                if let existingObservation = barcodeObservations[barcodeString], existingObservation.confidence > barcode.confidence {
                    continue
                }

                barcodeObservations[barcodeString] = barcode
            }

            for (_, barcodeObservation) in barcodeObservations {
                self.highlightQRCode(barcode: barcodeObservation)
            }
            for (barcodeContent, barcodeObservation) in barcodeObservations {
                self.drawTextBox(barcodeObservation: barcodeObservation, content: barcodeContent)
                self.searchProductBySKU(barcode: barcodeContent)
            }
        }
    }

    private func searchProductBySKU(barcode: String) {
        throttler.throttle {
            DispatchQueue.main.async {
                let action = ProductAction.searchProductBySKU(siteID: self.siteID, sku: barcode) { [weak self] result in
                    guard let self = self else {
                        return
                    }
                    switch result {
                    case .success(let product):
                        let generator = UINotificationFeedbackGenerator()
                        generator.notificationOccurred(.success)

                        self.resultsNavigationController.present(by: self)
                        self.resultsNavigationController.productScanned(product: product)
                    case .failure(let error):
                        print("No product matched: \(error)")
                    }
                }
                ServiceLocator.stores.dispatch(action)
            }
        }
    }

    // Draw a box around each QRCode
    func highlightQRCode(barcode: VNBarcodeObservation) {
        let barcodeBounds = self.adjustBoundsToScreen(barcode: barcode)

        let outline = CALayer()
        outline.frame = barcodeBounds
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.red.cgColor

        // We are inserting the highlights at the beginning of the sublayer queue
        // To avoid overlapping with the textboxes
        videoOutputImageView.layer.addSublayer(outline)
    }

    func drawTextBox(barcodeObservation: VNBarcodeObservation, content: String) {
        let barcodeBounds = self.adjustBoundsToScreen(barcode: barcodeObservation)

        let textLayerFrame: CGRect = CGRect(x: barcodeBounds.origin.x + barcodeBounds.size.width, y: barcodeBounds.origin.y - textBoxSize.height,
                                            width: textBoxSize.width, height: textBoxSize.height)
        if videoOutputImageView.bounds.contains(textLayerFrame) {
            // Readjust box locations so that there aren't any overlapping ones...
            guard let readjustedFrame = self.readjustBoxLocationBasedOnExistingLayers(originalBox: textLayerFrame, barcodeSize: barcodeBounds.size) else {
                return
            }

            let textBox = self.createTextLayer(content: content, frame: readjustedFrame)
            textBox.name = content

            videoOutputImageView.layer.addSublayer(textBox)
            totalNumberOfTextBoxes += 1
        }
    }

    func createTextLayer(content: String, frame: CGRect) -> CATextLayer {
        let textBox = CATextLayer()
        textBox.frame = frame
        textBox.backgroundColor = UIColor.white.cgColor
        textBox.cornerRadius = 6.0

        textBox.shadowRadius = 3.0
        textBox.shadowOffset = CGSize(width: 0, height: 0)
        textBox.shadowColor = UIColor.black.cgColor
        textBox.shadowOpacity = 0.9

        let textBoxString = NSAttributedString(string: content, attributes: self.contentFormatting)
        textBox.string = textBoxString

        textBox.contentsScale = UIScreen.main.scale
        textBox.isWrapped = true

        return textBox
    }

    func adjustBoundsToScreen(barcode: VNBarcodeObservation) -> CGRect {
        // Current origin is on the bottom-left corner
        let xCord = barcode.boundingBox.origin.x * videoOutputImageView.frame.size.width
        var yCord = (1 - barcode.boundingBox.origin.y) * videoOutputImageView.frame.size.height
        let width = barcode.boundingBox.size.width * videoOutputImageView.frame.size.width
        var height = -1 * barcode.boundingBox.size.height * videoOutputImageView.frame.size.height

        // Re-adjust origin to be on the top-left corner, so that calculations can be standardized
        yCord += height
        height *= -1

        return CGRect(x: xCord, y: yCord, width: width, height: height)
    }

    // Re-adjusts the given box's location based on other boxes that exist on other layers, so that boxes don't overlap
    // Returns nil if there is nowhere to place the box on
    func readjustBoxLocationBasedOnExistingLayers(originalBox: CGRect, barcodeSize: CGSize) -> CGRect? {
        guard let videoOutputLayers: [CALayer] = videoOutputImageView.layer.sublayers else {
            return nil
        }

        // Skip the first layer (i.e. the video layer) and outline layers
        let textBoxLayers: [CALayer] = Array(videoOutputLayers[(videoOutputLayers.count - totalNumberOfTextBoxes)...]);

        let bottomLeftAnchorBox = originalBox;
        let topLeftAnchorBox = CGRect(x: originalBox.origin.x, y: originalBox.origin.y + originalBox.size.height + barcodeSize.height,
                                      width: originalBox.size.width, height: originalBox.size.height)
        let topRightAnchorBox = CGRect(x: originalBox.origin.x - barcodeSize.width - originalBox.size.width, y: originalBox.origin.y + barcodeSize.height + originalBox.size.height,
                                       width: originalBox.size.width, height: originalBox.size.height)
        let bottomRightAnchorBox = CGRect(x: originalBox.origin.x - barcodeSize.width - originalBox.size.width, y: originalBox.origin.y,
                                          width: originalBox.size.width, height: originalBox.size.height)
        var potentialBoxes: [BoxAnchorLocation : CGRect] = [
            .bottomLeft : bottomLeftAnchorBox,
            .topLeft : topLeftAnchorBox,
            .topRight : topRightAnchorBox,
            .bottomRight : bottomRightAnchorBox
        ]

        var potentialBoxToUse: (CGRect?, BoxAnchorLocation) = (nil, .none)
        for layer in textBoxLayers {
            for (type, potentialBox) in potentialBoxes {
                if videoOutputImageView.bounds.contains(potentialBox) && !potentialBox.intersects(layer.frame) {
                    potentialBoxToUse = (potentialBox, type)
                } else {
                    if potentialBoxToUse.1 == type {
                        potentialBoxToUse = (nil, .none)
                    }
                    potentialBoxes.removeValue(forKey: type)
                }
            }
        }

        if textBoxLayers.count < 1 {
            potentialBoxToUse = (originalBox, .bottomLeft)
        }

        return potentialBoxToUse.0
    }
}


// MARK: Configurations
//
private extension InventoryScannerViewController {
    func configureNavigation() {
        title = NSLocalizedString("Inventory scanner", comment: "")

        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonTapped))
    }
}

// MARK: Navigation
//
private extension InventoryScannerViewController {
    @objc func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

extension InventoryScannerViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    // Run Vision code with live stream
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }

        var requestOptions: [VNImageOption: Any] = [:]

        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics: camData]
        }

        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: requestOptions)

        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
}

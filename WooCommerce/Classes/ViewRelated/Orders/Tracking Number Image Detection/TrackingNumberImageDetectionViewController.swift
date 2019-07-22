import UIKit
import Vision

extension CGRect {
    // TODO: unit tests.
    func calculateFrame(originalParentSize: CGSize, toFitIn containerSize: CGSize) -> CGRect {
        let scale = min(containerSize.width / originalParentSize.width, containerSize.height / originalParentSize.height)
        let scaleTransform = CGAffineTransform(scaleX: scale, y: scale)

        // Scale rect with image.
        let newSize = size.applying(scaleTransform)

        // Offset rect with image.
        let newParentSize = originalParentSize.applying(scaleTransform)
        let offsetTransform = CGAffineTransform(translationX: (containerSize.width - newParentSize.width) / 2.0,
                                                y: (containerSize.height - newParentSize.height) / 2.0)
        let newOrigin = origin
            .applying(scaleTransform)
            .applying(offsetTransform)
        let frame = CGRect(origin: newOrigin, size: newSize)
        return frame
    }
}

@available(iOS 13.0, *)
extension VNRecognizedText: TrackingNumberImageDetectionResult {}

@available(iOS 13.0, *)
class TrackingNumberImageDetectionViewController: UIViewController {
    // MARK: init properties
    private let image: UIImage

    typealias OnTrackingNumberDetection = (_ trackingNumber: String) -> ()
    private let onTrackingNumberDetection: OnTrackingNumberDetection

    // MARK: subviews
    private lazy var imageView: UIImageView = {
        return UIImageView(image: nil)
    }()

    private var debugImageView: UIImageView = UIImageView(image: nil)
    // Selected image.
    private var selectedImage: UIImage?

    // Layer into which to draw bounding box paths.
    private var pathLayer: CALayer?

    // MARK: internal states
    // Image parameters for reuse throughout app
    private var imageWidth: CGFloat = 0
    private var imageHeight: CGFloat = 0

    lazy var textDetectionRequest: VNDetectTextRectanglesRequest = {
        let textDetectRequest = VNDetectTextRectanglesRequest(completionHandler: self.handleDetectedText)
        // Tell Vision to report bounding box around each character.
        textDetectRequest.reportCharacterBoxes = true
        return textDetectRequest
    }()

    lazy var barcodeDetectionRequest: VNDetectBarcodesRequest = {
        let barcodeDetectRequest = VNDetectBarcodesRequest(completionHandler: self.handleDetectedBarcodes)
        // Restrict detection to most common symbologies.
        barcodeDetectRequest.symbologies = [.QR, .Aztec, .UPCE]
        return barcodeDetectRequest
    }()

    @available(iOS 13.0, *)
    lazy var textRecognitionRequest: VNRecognizeTextRequest = {
        let request = VNRecognizeTextRequest(completionHandler: self.handleRecognizedText)
        // This doesn't require OCR on a live camera feed, select accurate for more accurate results.
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        return request
    }()

    init(image: UIImage, onTrackingNumberDetection: @escaping OnTrackingNumberDetection) {
        self.image = image
        self.onTrackingNumberDetection = onTrackingNumberDetection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Tap box to select", comment: "")

        view.backgroundColor = UIColor.white

        view.addSubview(imageView)
        view.pinSubviewToAllEdges(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        view.addSubview(debugImageView)
        debugImageView.frame.origin = CGPoint(x: 30, y: 30)

        show(image)

        // Convert from UIImageOrientation to CGImagePropertyOrientation.
        guard let cgOrientation = CGImagePropertyOrientation(rawValue: UInt32(image.imageOrientation.rawValue)) else {
            return
        }

        // Fire off request based on URL of chosen photo.
        guard let cgImage = image.cgImage else {
            return
        }
        performVisionRequest(image: cgImage,
                             orientation: cgOrientation)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first

        guard let point = touch?.location(in: imageView) else { return }

        if let touchedLayer = pathLayer?.presentation()?.hitTest(point) {
            guard let croppedImage = image.cgImage?.cropping(to: touchedLayer.frame) else {
                assertionFailure()
                return
            }
            let selectedImage = UIImage(cgImage: croppedImage)
            self.selectedImage = selectedImage
            debugImageView.image = selectedImage
            debugImageView.frame.size = selectedImage.size
            performTextRecognition(cgImage: croppedImage)
        }
    }
}

@available(iOS 13.0, *)
private extension TrackingNumberImageDetectionViewController {
    func show(_ image: UIImage) {

        // Remove previous paths & image
        pathLayer?.removeFromSuperlayer()
        pathLayer = nil
        imageView.image = nil

        // Account for image orientation by transforming view.
        let correctedImage = scaleAndOrient(image: image)

        // Place photo inside imageView.
        imageView.image = correctedImage
        imageView.frame.size = correctedImage.size

        // Transform image to fit screen.
        guard let cgImage = correctedImage.cgImage else {
            print("Trying to show an image not backed by CGImage!")
            return
        }

        let fullImageWidth = CGFloat(cgImage.width)
        let fullImageHeight = CGFloat(cgImage.height)

        let imageFrame = imageView.frame
        let widthRatio = fullImageWidth / imageFrame.width
        let heightRatio = fullImageHeight / imageFrame.height

        // ScaleAspectFit: The image will be scaled down according to the stricter dimension.
        let scaleDownRatio = max(widthRatio, heightRatio)

        // Cache image dimensions to reference when drawing CALayer paths.
        imageWidth = fullImageWidth / scaleDownRatio
        imageHeight = fullImageHeight / scaleDownRatio

        // Prepare pathLayer to hold Vision results.
        let xLayer = (imageFrame.width - imageWidth) / 2
        let yLayer = imageView.frame.minY + (imageFrame.height - imageHeight) / 2
        let drawingLayer = CALayer()
        drawingLayer.bounds = CGRect(x: xLayer, y: yLayer, width: imageWidth, height: imageHeight)
        drawingLayer.anchorPoint = CGPoint.zero
        drawingLayer.position = CGPoint(x: xLayer, y: yLayer)
        drawingLayer.opacity = 0.5
        pathLayer = drawingLayer
        imageView.layer.addSublayer(pathLayer!)
        drawingLayer.frame = imageView.bounds
    }

    // MARK: - Vision

    /// - Tag: PerformRequests
    func performVisionRequest(image: CGImage, orientation: CGImagePropertyOrientation) {

        // Fetch desired requests based on switch status.
        let requests = createVisionRequests()
        // Create a request handler.
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: orientation,
                                                        options: [:])

        // Send the requests to the request handler.
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try imageRequestHandler.perform(requests)
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                self.presentAlert("Image Request Failed", error: error)
                return
            }
        }
    }

    /// - Tag: CreateRequests
    func createVisionRequests() -> [VNRequest] {

        // Create an array to collect all desired requests.
        var requests: [VNRequest] = []
        requests.append(self.textDetectionRequest)
        requests.append(self.barcodeDetectionRequest)

        // Return grouped requests as a single array.
        return requests
    }

    func handleDetectedRectangles(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            self.presentAlert("Rectangle Detection Error", error: nsError)
            return
        }
        // Since handlers are executing on a background thread, explicitly send draw calls to the main thread.
        DispatchQueue.main.async {
            guard let drawLayer = self.pathLayer,
                let results = request?.results as? [VNRectangleObservation] else {
                    return
            }
            self.draw(rectangles: results, onImageWithBounds: drawLayer.bounds)
            drawLayer.setNeedsDisplay()
        }
    }

    func handleDetectedText(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            self.presentAlert("Text Detection Error", error: nsError)
            return
        }
        // Perform drawing on the main thread.
        DispatchQueue.main.async {
            guard let drawLayer = self.pathLayer,
                let results = request?.results as? [VNTextObservation] else {
                    return
            }
            self.draw(text: results, onImageWithBounds: drawLayer.bounds)
            drawLayer.setNeedsDisplay()
        }
    }

    func handleDetectedBarcodes(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            self.presentAlert("Barcode Detection Error", error: nsError)
            return
        }
        // Perform drawing on the main thread.
        DispatchQueue.main.async {
            guard let drawLayer = self.pathLayer,
                let results = request?.results as? [VNBarcodeObservation] else {
                    return
            }
            self.draw(barcodes: results, onImageWithBounds: drawLayer.bounds)
            drawLayer.setNeedsDisplay()
        }
    }

    // MARK: - Path-Drawing

    func boundingBox(forRegionOfInterest: CGRect, withinImageBounds bounds: CGRect) -> CGRect {

        let imageWidth = bounds.width
        let imageHeight = bounds.height

        // Begin with input rect.
        var rect = forRegionOfInterest

        // Reposition origin.
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.origin.x
        rect.origin.y = (1 - rect.origin.y) * imageHeight + bounds.origin.y

        // Rescale normalized coordinates.
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight

        return rect
    }

    func textShapeLayer(color: UIColor, frame: CGRect) -> TextShapeLayer {
        // Create a new layer.
        let layer = TextShapeLayer(color: color)

        // Locate the layer.
        layer.anchorPoint = .zero
        layer.frame = frame
        layer.masksToBounds = true

        // Transform the layer to have same coordinate system as the imageView underneath it.
        layer.transform = CATransform3DMakeScale(1, -1, 1)

        return layer
    }

    func shapeLayer(color: UIColor, frame: CGRect) -> CAShapeLayer {
        // Create a new layer.
        let layer = CAShapeLayer()

        // Configure layer's appearance.
        layer.fillColor = nil // No fill to show boxed object
        layer.shadowOpacity = 0
        layer.shadowRadius = 0
        layer.borderWidth = 2

        // Vary the line color according to input.
        layer.borderColor = color.cgColor

        // Locate the layer.
        layer.anchorPoint = .zero
        layer.frame = frame
        layer.masksToBounds = true

        // Transform the layer to have same coordinate system as the imageView underneath it.
        layer.transform = CATransform3DMakeScale(1, -1, 1)

        return layer
    }

    // Rectangles are BLUE.
    func draw(rectangles: [VNRectangleObservation], onImageWithBounds bounds: CGRect) {
        CATransaction.begin()
        for observation in rectangles {
            let rectBox = boundingBox(forRegionOfInterest: observation.boundingBox, withinImageBounds: bounds)
            let rectLayer = shapeLayer(color: .blue, frame: rectBox)

            // Add to pathLayer on top of image.
            pathLayer?.addSublayer(rectLayer)
        }
        CATransaction.commit()
    }

    // Lines of text are RED.  Individual characters are PURPLE.
    func draw(text: [VNTextObservation], onImageWithBounds bounds: CGRect) {
        CATransaction.begin()
        for wordObservation in text {
            let wordBox = boundingBox(forRegionOfInterest: wordObservation.boundingBox, withinImageBounds: bounds)

            let containerSize = imageView.frame.size
            let originalSize = image.size

            let frame = wordBox.calculateFrame(originalParentSize: originalSize,
                                               toFitIn: containerSize)

            let wordLayer = textShapeLayer(color: .red, frame: frame)

            // Add to pathLayer on top of image.
            pathLayer?.addSublayer(wordLayer)
        }
        CATransaction.commit()
    }

    // Barcodes are ORANGE.
    func draw(barcodes: [VNBarcodeObservation], onImageWithBounds bounds: CGRect) {
        CATransaction.begin()
        for observation in barcodes {
            let barcodeBox = boundingBox(forRegionOfInterest: observation.boundingBox, withinImageBounds: bounds)
            let barcodeLayer = shapeLayer(color: .orange, frame: barcodeBox)

            // Add to pathLayer on top of image.
            pathLayer?.addSublayer(barcodeLayer)
        }
        CATransaction.commit()
    }
}

@available(iOS 13.0, *)
private extension TrackingNumberImageDetectionViewController {
    // MARK: - Helper Methods

    /// - Tag: PreprocessImage
    func scaleAndOrient(image: UIImage) -> UIImage {

        // Set a default value for limiting image size.
        let maxResolution: CGFloat = 640

        guard let cgImage = image.cgImage else {
            print("UIImage has no CGImage backing it!")
            return image
        }

        // Compute parameters for transform.
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        var transform = CGAffineTransform.identity

        var bounds = CGRect(x: 0, y: 0, width: width, height: height)

        if width > maxResolution ||
            height > maxResolution {
            let ratio = width / height
            if width > height {
                bounds.size.width = maxResolution
                bounds.size.height = round(maxResolution / ratio)
            } else {
                bounds.size.width = round(maxResolution * ratio)
                bounds.size.height = maxResolution
            }
        }

        let scaleRatio = bounds.size.width / width
        let orientation = image.imageOrientation
        switch orientation {
        case .up:
            transform = .identity
        case .down:
            transform = CGAffineTransform(translationX: width, y: height).rotated(by: .pi)
        case .left:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(translationX: 0, y: width).rotated(by: 3.0 * .pi / 2.0)
        case .right:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(translationX: height, y: 0).rotated(by: .pi / 2.0)
        case .upMirrored:
            transform = CGAffineTransform(translationX: width, y: 0).scaledBy(x: -1, y: 1)
        case .downMirrored:
            transform = CGAffineTransform(translationX: 0, y: height).scaledBy(x: 1, y: -1)
        case .leftMirrored:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(translationX: height, y: width).scaledBy(x: -1, y: 1).rotated(by: 3.0 * .pi / 2.0)
        case .rightMirrored:
            let boundsHeight = bounds.size.height
            bounds.size.height = bounds.size.width
            bounds.size.width = boundsHeight
            transform = CGAffineTransform(scaleX: -1, y: 1).rotated(by: .pi / 2.0)
        @unknown default:
            assertionFailure()
        }

        return UIGraphicsImageRenderer(size: bounds.size).image { rendererContext in
            let context = rendererContext.cgContext

            if orientation == .right || orientation == .left {
                context.scaleBy(x: -scaleRatio, y: scaleRatio)
                context.translateBy(x: -height, y: 0)
            } else {
                context.scaleBy(x: scaleRatio, y: -scaleRatio)
                context.translateBy(x: 0, y: -height)
            }
            context.concatenate(transform)
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        }
    }
}

// MARK: iOS 13+
@available(iOS 13.0, *)
private extension TrackingNumberImageDetectionViewController {
    func performTextRecognition(cgImage: CGImage) {
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([textRecognitionRequest])
        } catch {
            print(error)
        }
    }

    func handleRecognizedText(request: VNRequest, error: Error?) {
        guard let result = request.results?.first as? VNRecognizedTextObservation else {
            return
        }
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            guard let selectedImage = self.selectedImage else {
                assertionFailure()
                return
            }
            let resultsViewController = TrackingNumberImageDetectionResultsViewController(image: selectedImage,
                                                                                          results: result.topCandidates(10),
                                                                                          onResultSelection: self.didSelectResult)
            self.navigationController?.pushViewController(resultsViewController, animated: true)
            print(result.topCandidates(10))
        }
    }

    func didSelectResult(string: String) {
        print(string)
        onTrackingNumberDetection(string)
    }
}

@available(iOS 13.0, *)
private extension TrackingNumberImageDetectionViewController {
    func presentAlert(_ title: String, error: NSError) {
        // Always present alert on main thread.
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title,
                                                    message: error.localizedDescription,
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK",
                                         style: .default) { _ in
                                            // Do nothing -- simply dismiss alert.
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

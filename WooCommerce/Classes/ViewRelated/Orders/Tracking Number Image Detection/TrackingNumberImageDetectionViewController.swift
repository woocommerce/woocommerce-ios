import SVProgressHUD
import UIKit
import Vision

private struct RecognizedText: TrackingNumberImageDetectionResult {
    let string: String
    let confidence: Float
}

@available(iOS 13.0, *)
extension VNRecognizedText: TrackingNumberImageDetectionResult {}

@available(iOS 13.0, *)
/// `VNRecognizeTextRequest` is the only class that requires iOS 13+.
class TrackingNumberImageDetectionViewController: UIViewController {
    // MARK: init properties
    private let originalImage: UIImage

    // Account for image orientation by transforming the original image.
    private lazy var correctedImage: UIImage = {
        return originalImage.scaleAndOrient(maxDimension: maxImageDimension)
    }()

    typealias OnTrackingNumberDetection = (_ trackingNumber: String) -> ()
    private let onTrackingNumberDetection: OnTrackingNumberDetection

    // MARK: constants
    private let maxImageDimension = CGFloat(1600)

    // MARK: subviews
    private lazy var imageView: UIImageView = {
        return UIImageView(image: nil)
    }()

    // Selected image.
    private var selectedImage: UIImage?

    // Layer into which to draw bounding box paths.
    private var pathLayer: CALayer?

    // MARK: internal states
    // Whether a text region is being recognized.
    private var isTextRecognitionRunning: Bool = false

    // Image parameters for reuse throughout app
    private var imageWidth: CGFloat = 0
    private var imageHeight: CGFloat = 0

    lazy var textDetectionRequest: VNDetectTextRectanglesRequest = {
        let textDetectRequest = VNDetectTextRectanglesRequest(completionHandler: self.handleDetectedText)
        // Tell Vision to report bounding box around each character.
        textDetectRequest.reportCharacterBoxes = true
        return textDetectRequest
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
        self.originalImage = image
        self.onTrackingNumberDetection = onTrackingNumberDetection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = NSLocalizedString("Tap tracking number", comment: "")

        view.backgroundColor = UIColor.white

        view.addSubview(imageView)
        view.pinSubviewToAllEdges(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit

        show(correctedImage)

        // Convert from UIImageOrientation to CGImagePropertyOrientation.
        guard let cgOrientation = CGImagePropertyOrientation(rawValue: UInt32(correctedImage.imageOrientation.rawValue)) else {
            return
        }

        // Fire off request based on URL of chosen photo.
        guard let cgImage = correctedImage.cgImage else {
            return
        }
        performTextDetection(image: cgImage,
                             orientation: cgOrientation)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first

        guard let point = touch?.location(in: imageView) else { return }

        if let touchedLayer = pathLayer?.presentation()?.hitTest(point) as? TextShapeLayer {
            // Notes: somehow have to transform the frame like `layer.transform = CATransform3DMakeScale(1, -1, 1)`
            let frame = touchedLayer.frameInOrigialImage
                .applying(CGAffineTransform(translationX: 0, y: -touchedLayer.frameInOrigialImage.height))
            guard let croppedImage = correctedImage.cropping(to: frame).cgImage else {
                assertionFailure()
                return
            }
            // Add some margin to the text region for the selected image to be shown in the next screen.
            let frameForSelectedImage = frame.inset(by: UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10))
            let selectedImage = correctedImage.cropping(to: frameForSelectedImage)
            self.selectedImage = selectedImage

            // Show spinner.
            updateSpinner(shouldShow: true)

            performTextRecognition(cgImage: croppedImage)
        }
    }
}

@available(iOS 13.0, *)
private extension TrackingNumberImageDetectionViewController {
    func show(_ image: UIImage) {
        // Remove previous paths & image.
        pathLayer?.removeFromSuperlayer()
        pathLayer = nil
        imageView.image = nil

        // Place photo inside imageView.
        imageView.image = image

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
    func performTextDetection(image: CGImage, orientation: CGImagePropertyOrientation) {
        let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                        orientation: orientation,
                                                        options: [:])

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                return
            }
            do {
                try imageRequestHandler.perform([self.textDetectionRequest])
            } catch let error as NSError {
                print("Failed to perform image request: \(error)")
                self.presentAlert("Image Request Failed", error: error)
                return
            }
        }
    }

    func handleDetectedText(request: VNRequest?, error: Error?) {
        if let nsError = error as NSError? {
            self.presentAlert("Text Detection Error", error: nsError)
            return
        }
        // Perform drawing on the main thread.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            guard let drawLayer = self.pathLayer,
                let results = request?.results as? [VNTextObservation] else {
                    return
            }
            self.draw(text: results, onImageWithBounds: self.imageView.bounds)
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

    func textShapeLayer(color: UIColor, frame: CGRect, frameInOrigialImage: CGRect) -> TextShapeLayer {
        // Create a new layer.
        let layer = TextShapeLayer(color: color, frameInOrigialImage: frameInOrigialImage)

        // Locate the layer.
        layer.anchorPoint = .zero
        layer.frame = frame
        layer.masksToBounds = true

        // Transform the layer to have same coordinate system as the imageView underneath it.
        layer.transform = CATransform3DMakeScale(1, -1, 1)

        return layer
    }

    // Lines of text are RED.  Individual characters are PURPLE.
    func draw(text: [VNTextObservation], onImageWithBounds bounds: CGRect) {
        guard !text.isEmpty else {
            presentAlert(title: NSLocalizedString("No text found", comment: ""),
                         messsage: NSLocalizedString("Please try another image with clear text", comment: "")) { [weak self] in
                            self?.navigationController?.popViewController(animated: true)
            }
            return
        }

        CATransaction.begin()
        for wordObservation in text {
            let containerSize = imageView.frame.size
            let originalSize = correctedImage.size

            let wordBox = boundingBox(forRegionOfInterest: wordObservation.boundingBox, withinImageBounds: CGRect(origin: .zero, size: originalSize))

            let frame = wordBox.calculateFrame(originalParentSize: originalSize,
                                               toFitIn: containerSize)

            let wordLayer = textShapeLayer(color: .primaryButtonTitle, frame: frame, frameInOrigialImage: wordBox)

            // Add to pathLayer on top of image.
            pathLayer?.addSublayer(wordLayer)
        }
        CATransaction.commit()
    }
}

// MARK: iOS 13+
@available(iOS 13.0, *)
private extension TrackingNumberImageDetectionViewController {
    func performTextRecognition(cgImage: CGImage) {
        guard !isTextRecognitionRunning else {
            return
        }
        isTextRecognitionRunning = true
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                return
            }
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([self.textRecognitionRequest])
                self.isTextRecognitionRunning = false
            } catch {
                print(error)
            }
        }
    }

    func handleRecognizedText(request: VNRequest, error: Error?) {
        DispatchQueue.main.async { [weak self] in
            self?.updateSpinner(shouldShow: false)
            guard let result = request.results?.first as? VNRecognizedTextObservation else {
                return
            }
            guard let self = self else {
                return
            }
            guard let selectedImage = self.selectedImage else {
                assertionFailure()
                return
            }

            // Remove any non-alphanumerical characters in each result text, deduplicate and sort by confidence.
            guard let nonAlphanumericRegex = try? NSRegularExpression(pattern: "[^a-zA-Z0-9]", options: []) else {
                return
            }
            let results = result.topCandidates(10)
                .map({ (result: VNRecognizedText) -> TrackingNumberImageDetectionResult in
                    let text = result.string
                    let range = NSMakeRange(0, text.count)
                    let alphanumericalText = nonAlphanumericRegex.stringByReplacingMatches(in: text,
                                                                         options: [],
                                                                         range: range,
                                                                         withTemplate: "")
                    return RecognizedText(string: alphanumericalText, confidence: result.confidence)
                })
                .sorted { (lhs, rhs) -> Bool in
                    return lhs.confidence > rhs.confidence
                }

            var deduplicatedResults = [TrackingNumberImageDetectionResult]()
            for result in results {
                let hasDuplicateText = deduplicatedResults.contains(where: { (anotherResult: TrackingNumberImageDetectionResult) -> Bool in
                    return result.string == anotherResult.string
                })
                if !hasDuplicateText {
                    deduplicatedResults.append(result)
                }
            }

            let resultsViewController = TrackingNumberImageDetectionResultsViewController(image: selectedImage,
                                                                                          results: deduplicatedResults,
                                                                                          onResultSelection: self.didSelectResult)
            self.navigationController?.pushViewController(resultsViewController, animated: true)
        }
    }

    func didSelectResult(string: String) {
        onTrackingNumberDetection(string)
    }
}

@available(iOS 13.0, *)
private extension TrackingNumberImageDetectionViewController {
    func presentAlert(_ title: String, error: NSError) {
        presentAlert(title: title, messsage: error.localizedDescription)
    }

    func presentAlert(title: String?, messsage: String?, action: (() -> ())? = nil) {
        // Always present alert on main thread.
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            let alertController = UIAlertController(title: title,
                                                    message: messsage,
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK",
                                         style: .default) { _ in
                                            action?()
            }
            alertController.addAction(okAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func updateSpinner(shouldShow: Bool) {
        if shouldShow {
            SVProgressHUD.show(withStatus: NSLocalizedString("Detecting text...", comment: ""))
        } else {
            SVProgressHUD.dismiss()
        }
    }
}

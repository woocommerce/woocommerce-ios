import Foundation
import Yosemite

import Foundation
import Combine
import CoreImage.CIFilterBuiltins
import UIKit
import Vision

/// Presets for the subjects' visual effects.
enum Effect: String, Equatable, CaseIterable {
    case none = "None"
    case highlight = "Highlight"
    case bokeh = "Bokeh Halo"
    case noir = "Noir"
}

/// Presets for the background's visual effects.
enum Background: String, Equatable, CaseIterable {
    case original = "Original"
    case transparent = "Transparent"
    // TODO-jc: support background images
//    case sunset = "Sunset"
    case greenScreen = "Green Screen"
}

@available(iOS 17.0, *)
final class ProductImageBackgroundRemovalViewModel: ObservableObject {
    /// The source image for the background effects pipeline.
    @Published var inputImage: CIImage?

    /// The final output image with the effects applied to the lifted subjects.
    @Published var output = UIImage()

    /// The selected visual effect.
    @Published var effect: Effect = .none

    /// The selected background.
    @Published var background: Background = .transparent

    /// An optional normalized point for selecting a subject instance.
    @Published var subjectPosition: CGPoint? = nil

    private let productImage: ProductImage
    private let imageLoader: ProductUIImageLoader
    private let actionHandler: ProductImageActionHandlerProtocol
    private let onSave: () -> Void

    private let processingQueue = DispatchQueue(label: "ProductImageBackgroundProcessing")

    private var cancellables: [AnyCancellable] = []

    init(productImage: ProductImage,
         imageLoader: ProductUIImageLoader,
         actionHandler: ProductImageActionHandlerProtocol,
         onSave: @escaping () -> Void) {
        self.productImage = productImage
        self.imageLoader = imageLoader
        self.actionHandler = actionHandler
        self.onSave = onSave

        // Regenerates the image when the pipeline input changes.
        Publishers
            .CombineLatest4(
                $inputImage.compactMap { $0 },
                $effect,
                $background,
                $subjectPosition)
            .sink { [weak self] (inputImage, effect, background, subjectPosition) in
                guard let self else { return }
                self.regenerate(
                    usingInputImage: inputImage,
                    effect: effect,
                    background: background,
                    subjectPosition: subjectPosition
                )
            }
            .store(in: &self.cancellables)

        imageLoader.requestImage(productImage: productImage) { [weak self] image in
            self?.inputImage = CIImage(image: image)
        }?.store(in: &cancellables)
    }

    func saveToProduct() {
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .uiImage(image: output, filename: productImage.name, altText: productImage.alt))
        onSave()
    }
}

@available(iOS 17.0, *)
private extension ProductImageBackgroundRemovalViewModel {
    // Refresh the pipeline and generate a new output.
    private func regenerate(usingInputImage inputImage: CIImage,
                            effect: Effect,
                            background: Background,
                            subjectPosition: CGPoint?) {
        processingQueue.async {
            // Generates the input-image mask.
            guard let mask = subjectMask(fromImage: inputImage, atPoint: subjectPosition) else {
                return
            }

            // Acquire the selected background image.
            let backgroundImage = image(forBackground: background, inputImage: inputImage)
                .cropped(to: inputImage.extent)

            // Apply the visual effect and composite.
            let composited = apply(effect: effect,
                                   toInputImage: inputImage,
                                   background: backgroundImage,
                                   mask: mask)

            let output = UIImage(cgImage: render(ciImage: composited))

            DispatchQueue.main.async {
                self.output = output
            }
        }
    }
}

/// Applies the current effect and returns the composited image.
private func apply(
    effect: Effect,
    toInputImage inputImage: CIImage,
    background: CIImage,
    mask: CIImage
) -> CIImage {

    var postEffectBackground = background

    switch effect {
    case .none:
        break

    case .highlight:
        let filter = CIFilter.exposureAdjust()
        filter.inputImage = background
        filter.ev = -3
        postEffectBackground = filter.outputImage!

    case .bokeh:
        let filter = CIFilter.bokehBlur()
        filter.inputImage = apply(
            effect: .none,
            toInputImage: CIImage(color: .white)
                .cropped(to: inputImage.extent),
            background: background,
            mask: mask)
        filter.ringSize = 1
        filter.ringAmount = 1
        filter.softness = 1.0
        filter.radius = 20
        postEffectBackground = filter.outputImage!

    case .noir:
        let filter = CIFilter.photoEffectNoir()
        filter.inputImage = background
        postEffectBackground = filter.outputImage!
    }

    let filter = CIFilter.blendWithMask()
    filter.inputImage = inputImage
    filter.backgroundImage = postEffectBackground
    filter.maskImage = mask
    return filter.outputImage!
}

/// Returns the subject alpha mask for the given image.
///
/// - parameter image: The image to extract a foreground subject from.
/// - parameter atPoint: An optional normalized point for selecting a subject instance.
@available(iOS 17.0, *)
private func subjectMask(fromImage image: CIImage, atPoint point: CGPoint?) -> CIImage? {
    // Create a request.
    let request = VNGenerateForegroundInstanceMaskRequest()

    // Create a request handler.
    let handler = VNImageRequestHandler(ciImage: image)

    // Perform the request.
    do {
        try handler.perform([request])
    } catch {
        print("Failed to perform Vision request.")
        return nil
    }

    // Acquire the instance mask observation.
    guard let result = request.results?.first else {
        print("No subject observations found.")
        return nil
    }

    let instances = instances(atPoint: point, inObservation: result)

    // Create a matted image with the subject isolated from the background.
    do {
        let mask = try result.generateScaledMaskForImage(forInstances: instances, from: handler)
        return CIImage(cvPixelBuffer: mask)
    } catch {
        print("Failed to generate subject mask.")
        return nil
    }
}

/// Returns the indices of the instances at the given point.
///
/// - parameter atPoint: A point with a top-left origin, normalized within the range [0, 1].
/// - parameter inObservation: The observation instance to extract subject indices from.
@available(iOS 17.0, *)
private func instances(
    atPoint maybePoint: CGPoint?,
    inObservation observation: VNInstanceMaskObservation
) -> IndexSet {
    guard let point = maybePoint else {
        return observation.allInstances
    }

    // Transform the normalized UI point to an instance map pixel coordinate.
    let instanceMap = observation.instanceMask
    let coords = VNImagePointForNormalizedPoint(
        point,
        CVPixelBufferGetWidth(instanceMap) - 1,
        CVPixelBufferGetHeight(instanceMap) - 1)

    // Look up the instance label at the computed pixel coordinate.
    CVPixelBufferLockBaseAddress(instanceMap, .readOnly)
    guard let pixels = CVPixelBufferGetBaseAddress(instanceMap) else {
        fatalError("Failed to access instance map data.")
    }
    let bytesPerRow = CVPixelBufferGetBytesPerRow(instanceMap)
    let instanceLabel = pixels.load(
        fromByteOffset: Int(coords.y) * bytesPerRow + Int(coords.x),
        as: UInt8.self)
    CVPixelBufferUnlockBaseAddress(instanceMap, .readOnly)

    // If the point lies on the background, select all instances.
    // Otherwise, restrict this to just the selected instance.
    return instanceLabel == 0 ? observation.allInstances : [Int(instanceLabel)]
}

/// Returns the image for the given background preset.
private func image(forBackground background: Background, inputImage: CIImage) -> CIImage {
    switch background {
    case .original:
        return inputImage
    case .transparent:
        return CIImage(color: CIColor.clear)
    case .greenScreen:
        return CIImage(color: CIColor.green)
//    case .sunset:
//        // Load the background image
//        var bgImage = loadImage(named: "sunset")
//
//        // Upsample the background image if the input image is larger.
//        let scale = max(inputImage.extent.width / bgImage.extent.width,
//                        inputImage.extent.height / bgImage.extent.height)
//        if scale > 1.0 {
//            bgImage = bgImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
//        }
//
//        return bgImage
    }
}

/// Loads a bundled image asset by name.
private func loadImage(named: String, withExtension ext: String = "jpg") -> CIImage {
    guard let url = Bundle.main.url(forResource: named, withExtension: ext) else {
        fatalError("Sample image asset \(named) not found.")
    }
    guard let image = CIImage(contentsOf: url) else {
        fatalError("Failed to load sample image \(named) data.")
    }
    return image
}

/// Renders a CIImage onto a CGImage.
private func render(ciImage img: CIImage) -> CGImage {
    guard let cgImage = CIContext(options: nil).createCGImage(img, from: img.extent) else {
        fatalError("Failed to render CIImage.")
    }
    return cgImage
}

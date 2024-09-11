import SwiftUI
import Kingfisher

struct ProductImageThumbnail: View {
    private let productImageURL: URL?
    private let productImageSize: CGFloat
    private let scale: CGFloat
    private let productImageCornerRadius: CGFloat
    private let foregroundColor: Color
    private let cache: ImageCache = ImageCache.default

    /// Image processor to resize images in a background thread to avoid blocking the UI
    ///
    private var imageProcessor: ImageProcessor {
        ResizingImageProcessor(referenceSize:
                .init(width: productImageSize * scale,
                      height: productImageSize * scale),
                               mode: .aspectFill
        )
    }

    init(productImageURL: URL?, productImageSize: CGFloat, scale: CGFloat, productImageCornerRadius: CGFloat = 0, foregroundColor: Color) {
        self.productImageURL = productImageURL
        self.productImageSize = productImageSize
        self.scale = scale
        self.productImageCornerRadius = productImageCornerRadius
        self.foregroundColor = foregroundColor
    }

    var body: some View {
        KFImage
            .url(productImageURL)
            .placeholder {
                Image(uiImage: .productPlaceholderImage)
            }
            .setProcessor(imageProcessor)
            // If a processor is applied when retrieving an image, the processed image will be cached. We need to include the processor identifier when handling the cache
            .cacheMemoryOnly()
            .resizable()
            .scaledToFill()
            .frame(width: productImageSize * scale, height: productImageSize * scale)
            .cornerRadius(productImageCornerRadius)
            .foregroundColor(foregroundColor)
            .accessibilityHidden(true)
            .onAppear {
                // Temporary:
                let cacheKey = imageProcessor.identifier
                guard let image = productImageURL?.absoluteString else {
                    return
                }
                let isCached = cache.isCached(forKey: image, processorIdentifier: cacheKey)
                debugPrint("🍍 Image \(image) is cached? \(isCached)")
            }
    }
}

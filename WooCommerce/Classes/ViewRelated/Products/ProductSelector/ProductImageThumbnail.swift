import SwiftUI
import Kingfisher

struct ProductImageThumbnail: View {
    private let productImageURL: URL?
    private let productImageSize: CGFloat
    private let scale: CGFloat
    private let productImageCornerRadius: CGFloat
    private let foregroundColor: Color
    private let cache: ImageCache = ImageCache.default
    private let cachesOriginalImage: Bool

    /// Image processor to resize images in a background thread to avoid blocking the UI
    ///
    private var imageProcessor: ImageProcessor {
        ResizingImageProcessor(referenceSize: 
                .init(width: productImageSize * scale,
                      height: productImageSize * scale),
                               mode: .aspectFill)
    }

    init(productImageURL: URL?,
         productImageSize: CGFloat,
         scale: CGFloat,
         productImageCornerRadius: CGFloat = 0,
         foregroundColor: Color,
         cachesOriginalImage: Bool = false) {
        self.productImageURL = productImageURL
        self.productImageSize = productImageSize
        self.scale = scale
        self.productImageCornerRadius = productImageCornerRadius
        self.foregroundColor = foregroundColor
        self.cachesOriginalImage = cachesOriginalImage
    }

    var body: some View {
        KFImage
            .url(productImageURL)
            .cacheOriginalImage(cachesOriginalImage)
            .placeholder {
                Image(uiImage: .productPlaceholderImage)
            }
            .setProcessor(imageProcessor)
            .resizable()
            .scaledToFill()
            .frame(width: productImageSize * scale, height: productImageSize * scale)
            .cornerRadius(productImageCornerRadius)
            .foregroundColor(foregroundColor)
            .accessibilityHidden(true)
    }
}

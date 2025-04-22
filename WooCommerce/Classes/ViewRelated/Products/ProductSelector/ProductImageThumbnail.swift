import SwiftUI
import Kingfisher

struct ProductImageThumbnail<Placeholder: View>: View {
    private let productImageURL: URL?
    private let productImageSize: CGFloat
    private let scale: CGFloat
    private let productImageCornerRadius: CGFloat
    private let foregroundColor: Color
    private let cachesOriginalImage: Bool
    private let placeholder: Placeholder

    /// Image processor to resize images in a background thread to avoid blocking the UI
    ///
    private var imageProcessor: ImageProcessor {
        let screenPixelScale = UIScreen.main.scale
        let sideSize = productImageSize * screenPixelScale * scale
        let pixelSize = CGSize(
            width: sideSize,
            height: sideSize
        )
        return ResizingImageProcessor(
            referenceSize: pixelSize,
            mode: .aspectFill
        )
    }

    init(productImageURL: URL?,
         productImageSize: CGFloat,
         scale: CGFloat,
         productImageCornerRadius: CGFloat = 0,
         foregroundColor: Color,
         cachesOriginalImage: Bool = false,
         @ViewBuilder placeholder: () -> Placeholder) {
        self.productImageURL = productImageURL
        self.productImageSize = productImageSize
        self.scale = scale
        self.productImageCornerRadius = productImageCornerRadius
        self.foregroundColor = foregroundColor
        self.cachesOriginalImage = cachesOriginalImage
        self.placeholder = placeholder()
    }

    var body: some View {
        KFImage
            .url(productImageURL)
            .cacheOriginalImage(cachesOriginalImage)
            .placeholder {
                placeholder
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

// Convenience initializer that maintains the default behavior.
extension ProductImageThumbnail where Placeholder == Image {
    init(productImageURL: URL?,
         productImageSize: CGFloat,
         scale: CGFloat,
         productImageCornerRadius: CGFloat = 0,
         foregroundColor: Color,
         cachesOriginalImage: Bool = false) {
        self.init(productImageURL: productImageURL,
                 productImageSize: productImageSize,
                 scale: scale,
                 productImageCornerRadius: productImageCornerRadius,
                 foregroundColor: foregroundColor,
                 cachesOriginalImage: cachesOriginalImage) {
            Image(uiImage: .productPlaceholderImage)
        }
    }
}

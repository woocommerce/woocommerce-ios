import SwiftUI
import Kingfisher

struct ProductImageThumbnail: View {
    private let productImageURL: URL?
    private let productImageSize: CGFloat
    private let scale: CGFloat
    private let productImageCornerRadius: CGFloat
    private let foregroundColor: Color

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
        KFImage.url(productImageURL)
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

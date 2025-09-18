import SwiftUI
import struct WooFoundation.ProductImageThumbnail

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

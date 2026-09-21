import SwiftUI
import UIKit
import struct WooFoundation.ProductImageThumbnail

enum ProductThumbnailStyle {
    fileprivate static let cornerRadius: CGFloat = 2
    fileprivate static let borderWidth: CGFloat = 0.5
    static let placeholderImage: UIImage = .productsTabProductCellPlaceholderImage
    fileprivate static let backgroundColor: UIColor = .listForeground(modal: false)
    fileprivate static let borderColor: UIColor = .border
    fileprivate static let placeholderContentMode: UIView.ContentMode = .center
    fileprivate static let imageContentMode: UIView.ContentMode = .scaleAspectFill
}

extension UIImageView {
    func applyProductThumbnailStyle() {
        backgroundColor = ProductThumbnailStyle.backgroundColor
        layer.cornerRadius = ProductThumbnailStyle.cornerRadius
        layer.borderWidth = ProductThumbnailStyle.borderWidth
        refreshProductThumbnailBorderColor()
        clipsToBounds = true
    }

    func removeProductThumbnailStyle() {
        backgroundColor = nil
        layer.cornerRadius = 0
        layer.borderWidth = 0
        layer.borderColor = nil
        clipsToBounds = true
    }

    func showProductThumbnailPlaceholder() {
        image = ProductThumbnailStyle.placeholderImage
        contentMode = ProductThumbnailStyle.placeholderContentMode
    }

    func showProductThumbnailImage() {
        contentMode = ProductThumbnailStyle.imageContentMode
    }

    func refreshProductThumbnailBorderColor() {
        layer.borderColor = ProductThumbnailStyle.borderColor.cgColor
    }
}

// Convenience initializer for the app's default product thumbnail placeholder.
extension ProductImageThumbnail where Placeholder == ProductImageThumbnailPlaceholder {
    init(productImageURL: URL?,
         productImageSize: CGFloat,
         scale: CGFloat,
         productImageCornerRadius: CGFloat = ProductThumbnailStyle.cornerRadius,
         foregroundColor: Color,
         cachesOriginalImage: Bool = false) {
        self.init(productImageURL: productImageURL,
                 productImageSize: productImageSize,
                 scale: scale,
                 productImageCornerRadius: productImageCornerRadius,
                 foregroundColor: foregroundColor,
                 cachesOriginalImage: cachesOriginalImage) {
            ProductImageThumbnailPlaceholder(productImageSize: productImageSize,
                                             scale: scale,
                                             cornerRadius: productImageCornerRadius)
        }
    }
}

struct ProductImageThumbnailPlaceholder: View {
    private let productImageSize: CGFloat
    private let scale: CGFloat
    private let cornerRadius: CGFloat

    init(productImageSize: CGFloat,
         scale: CGFloat,
         cornerRadius: CGFloat) {
        self.productImageSize = productImageSize
        self.scale = scale
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        Image(uiImage: ProductThumbnailStyle.placeholderImage)
            .frame(width: productImageSize * scale, height: productImageSize * scale)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(ProductThumbnailStyle.backgroundColor))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(Color(ProductThumbnailStyle.borderColor), lineWidth: ProductThumbnailStyle.borderWidth)
            }
    }
}

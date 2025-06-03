import UIKit
import Yosemite

/// View model for displaying a collection of product images in the header.
final class ProductImagesHeaderViewModel {

    let productImageStatuses: [ProductImageStatus]

    let config: ProductImagesCellConfig

    /// Whether we should scroll to the beginning of the collection view.
    let shouldScrollToStart: Bool

    // Base size for accessibility scaling
    private static let baseCellSize: CGFloat = 128.0

    /// Returns the appropriate cell size based on the content size category for accessibility
    static func cellSize(for contentSizeCategory: UIContentSizeCategory) -> CGSize {
        let scaledSize = scaledValue(baseCellSize, contentSizeCategory: contentSizeCategory, maximumContentSizeCategory: .accessibilityExtraExtraExtraLarge)
        return CGSize(width: scaledSize, height: scaledSize)
    }

    /// Returns a scaled value using native iOS scaling, with a maximum cap for accessibility
    private static func scaledValue(_ value: CGFloat, contentSizeCategory: UIContentSizeCategory, maximumContentSizeCategory: UIContentSizeCategory) -> CGFloat {
        let metrics = UIFontMetrics.default
        let scaledValue = metrics.scaledValue(for: value, compatibleWith: .init(preferredContentSizeCategory: contentSizeCategory))

        let maximumScaledValue = metrics.scaledValue(for: value, compatibleWith: .init(preferredContentSizeCategory: maximumContentSizeCategory))

        return min(scaledValue, maximumScaledValue)
    }

    private(set) var items: [ProductImagesItem] = []

    init(productImageStatuses: [ProductImageStatus], config: ProductImagesCellConfig) {
        self.productImageStatuses = productImageStatuses
        self.config = config
        self.shouldScrollToStart = productImageStatuses.hasPendingUpload

        configureItems()
    }

    func configureItems() {
        items = []

        switch config {
        case .images:
            for productImageStatus in productImageStatuses {
                items.append(.image(status: productImageStatus))
            }
        case .addImages:
            for productImageStatus in productImageStatuses {
                items.append(.image(status: productImageStatus))
            }

            items.append(.addImage)
        case .extendedAddImages(let isVariation):
            items.append(.extendedAddImage(isVariation: isVariation))
        }
    }
}


// MARK: - Register collection view cells
//
extension ProductImagesHeaderViewModel {
    /// Registers all of the available CollectionViewCells
    ///
    func registerCollectionViewCells(_ collectionView: UICollectionView) {
        let cells = [
            ProductImageCollectionViewCell.self,
            InProgressProductImageCollectionViewCell.self,
            FailedProductImageCollectionViewCell.self,
            AddProductImageCollectionViewCell.self,
            ExtendedAddProductImageCollectionViewCell.self
        ]

        for cell in cells {
            collectionView.register(cell.loadNib(), forCellWithReuseIdentifier: cell.reuseIdentifier)
        }
    }
}

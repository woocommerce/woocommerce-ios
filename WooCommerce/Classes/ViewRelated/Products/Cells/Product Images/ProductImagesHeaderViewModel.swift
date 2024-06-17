import UIKit
import Yosemite

/// View model for displaying a collection of product images in the header.
final class ProductImagesHeaderViewModel {

    let productImageStatuses: [ProductImageStatus]

    let config: ProductImagesCellConfig

    /// Whether we should scroll to the beginning of the collection view.
    let shouldScrollToStart: Bool

    // Fixed width/height of collection view cell
    static let defaultCollectionViewCellSize = CGSize(width: 128.0, height: 128.0)

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
    @MainActor
    func registerCollectionViewCells(_ collectionView: UICollectionView) {
        let cells = [
            ProductImageCollectionViewCell.self,
            InProgressProductImageCollectionViewCell.self,
            AddProductImageCollectionViewCell.self,
            ExtendedAddProductImageCollectionViewCell.self
        ]

        for cell in cells {
            collectionView.register(cell.loadNib(), forCellWithReuseIdentifier: cell.reuseIdentifier)
        }
    }
}

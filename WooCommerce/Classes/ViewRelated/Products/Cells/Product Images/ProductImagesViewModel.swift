import UIKit
import Yosemite

final class ProductImagesViewModel {

    let productImageStatuses: [ProductImageStatus]

    let config: ProductImagesCellConfig

    // Fixed width/height of collection view cell
    static let defaultCollectionViewCellSize = CGSize(width: 128.0, height: 128.0)

    private(set) var items: [ProductImagesItem] = []

    init(productImageStatuses: [ProductImageStatus], config: ProductImagesCellConfig) {
        self.productImageStatuses = productImageStatuses
        self.config = config

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
        case .extendedAddImages:
            items.append(.extendedAddImage)
        }
    }
}


// MARK: - Register collection view cells
//
extension ProductImagesViewModel {
    /// Registers all of the available CollectionViewCells
    ///
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

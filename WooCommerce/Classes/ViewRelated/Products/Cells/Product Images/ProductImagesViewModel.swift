import UIKit
import Yosemite

final class ProductImagesViewModel {

    let product: Product

    let config: ProductImagesCellConfig

    // Fixed width/height of collection view cell
    static let defaultCollectionViewCellSize = CGSize(width: 128.0, height: 128.0)

    private(set) var items: [ProductImagesItem] = []

    init(product: Product, config: ProductImagesCellConfig) {
        self.product = product
        self.config = config

        configureItems()
    }

    func configureItems() {
        items = []

        switch config {
        case .images:
            for _ in product.images {
                items.append(.image)
            }
        case .addImages:
            for _ in product.images {
                items.append(.image)
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
            AddProductImageCollectionViewCell.self,
            ExtendedAddProductImageCollectionViewCell.self
        ]

        for cell in cells {
            collectionView.register(cell.loadNib(), forCellWithReuseIdentifier: cell.reuseIdentifier)
        }
    }
}

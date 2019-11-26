import UIKit

final class ProductImagesCollectionViewDatasource: NSObject {
    private let viewModel: ProductImagesViewModel

    init(viewModel: ProductImagesViewModel) {
        self.viewModel = viewModel
        super.init()
    }
}

// MARK - Collection View DataSource methods
//
extension ProductImagesCollectionViewDatasource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.items.count
    }


    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = viewModel.items[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.reuseIdentifier, for: indexPath)
        configure(collectionView: collectionView, cell, for: item, at: indexPath)
        return cell
    }

}

// MARK: - Support methods for UICollectionViewDataSource
//
private extension ProductImagesCollectionViewDatasource {
    func configure(collectionView: UICollectionView, _ cell: UICollectionViewCell, for item: ProductImagesItem, at indexPath: IndexPath) {
        switch cell {
        case let cell as ProductImageCollectionViewCell where item == .image:
            configureImageCell(collectionView: collectionView, cell: cell, at: indexPath)
        case let cell as AddProductImageCollectionViewCell where item == .addImage:
            configureAddImageCell(collectionView: collectionView, cell: cell, at: indexPath)
        case let cell as ExtendedAddProductImageCollectionViewCell where item == .extendedAddImage:
            configureExtendedAddImageCell(collectionView: collectionView, cell: cell, at: indexPath)
        default:
            fatalError("Unidentified product image item type")
        }
    }

    /// Cell configuration
    ///
    func configureImageCell(collectionView: UICollectionView, cell: ProductImageCollectionViewCell, at indexPath: IndexPath) {
        let image = viewModel.product.images[indexPath.item]
        let imageURL = URL(string: image.src)
        cell.imageView.downloadImage(from: imageURL, placeholderImage: UIImage.productPlaceholderImage, success: { (image) in

//            if CGSize(width: (128 / image.size.height) * image.size.width, height: 128.0) != cell.frame.size{
//                let animationsStatus = UIView.areAnimationsEnabled
//                UIView.setAnimationsEnabled(false)
//                collectionView.reloadItems(at: [indexPath])
//                collectionView.collectionViewLayout.invalidateLayout()
//                UIView.setAnimationsEnabled(true)
//            }
        }) { (error) in
        }

    }

    func configureAddImageCell(collectionView: UICollectionView, cell: AddProductImageCollectionViewCell, at: IndexPath) {

    }
    
    func configureExtendedAddImageCell(collectionView: UICollectionView, cell: ExtendedAddProductImageCollectionViewCell, at: IndexPath) {

    }
}

enum ProductImagesItem {
    case image
    case addImage
    case extendedAddImage

    var reuseIdentifier: String {
        switch self {
        case .image:
            return ProductImageCollectionViewCell.reuseIdentifier
        case .addImage:
            return AddProductImageCollectionViewCell.reuseIdentifier
        case .extendedAddImage:
            return ExtendedAddProductImageCollectionViewCell.reuseIdentifier
        }
    }
}

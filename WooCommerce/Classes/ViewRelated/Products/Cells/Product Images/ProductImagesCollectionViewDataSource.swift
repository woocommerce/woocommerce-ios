import UIKit
import Kingfisher

final class ProductImagesCollectionViewDataSource: NSObject {
    private let viewModel: ProductImagesViewModel

    init(viewModel: ProductImagesViewModel) {
        self.viewModel = viewModel
        super.init()
    }
}

// MARK: - Collection View DataSource methods
//
extension ProductImagesCollectionViewDataSource: UICollectionViewDataSource {
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
private extension ProductImagesCollectionViewDataSource {
    func configure(collectionView: UICollectionView, _ cell: UICollectionViewCell, for item: ProductImagesItem, at indexPath: IndexPath) {
        switch cell {
        case let cell as ProductImageCollectionViewCell where item == .image:
            configureImageCell(collectionView: collectionView, cell: cell, at: indexPath)
        case _ as AddProductImageCollectionViewCell where item == .addImage:
            break
        case _ as ExtendedAddProductImageCollectionViewCell where item == .extendedAddImage:
            break
        default:
            fatalError("Unidentified product image item type: \(item)")
        }
    }

    /// Cell configuration
    ///
    func configureImageCell(collectionView: UICollectionView, cell: ProductImageCollectionViewCell, at indexPath: IndexPath) {
        let image = viewModel.product.images[indexPath.item]
        let imageURL = URL(string: image.src)
        cell.imageView.kf.setImage(with: imageURL, placeholder: UIImage.productPlaceholderImage) { (result) in
            switch result {
            case .success:
                cell.imageView.contentMode = .scaleAspectFit
            case .failure:
                cell.imageView.contentMode = .center
                break
            }
        }
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

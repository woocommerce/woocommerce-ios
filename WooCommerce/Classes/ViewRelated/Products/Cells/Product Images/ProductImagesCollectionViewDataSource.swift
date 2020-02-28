import Photos
import UIKit
import Kingfisher
import Yosemite

final class ProductImagesCollectionViewDataSource: NSObject {
    private let viewModel: ProductImagesViewModel
    private let productImagesProvider: ProductImagesProvider

    init(viewModel: ProductImagesViewModel,
         productImagesProvider: ProductImagesProvider) {
        self.viewModel = viewModel
        self.productImagesProvider = productImagesProvider
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
        switch item {
        case .image(let status):
            configureImageCell(cell, productImageStatus: status)
        default:
            break
        }
    }

    func configureImageCell(_ cell: UICollectionViewCell, productImageStatus: ProductImageStatus) {
        switch productImageStatus {
        case .remote(let image):
            configureRemoteImageCell(cell, productImage: image)
        case .uploading(let asset):
            configureUploadingImageCell(cell, asset: asset)
        }
    }

    func configureRemoteImageCell(_ cell: UICollectionViewCell, productImage: ProductImage) {
        guard let cell = cell as? ProductImageCollectionViewCell else {
            fatalError()
        }

        cell.imageView.contentMode = .center
        cell.imageView.image = .productsTabProductCellPlaceholderImage

        productImagesProvider.requestImage(productImage: productImage) { [weak cell] image in
            cell?.imageView.contentMode = .scaleAspectFit
            cell?.imageView.image = image
        }
    }

    func configureUploadingImageCell(_ cell: UICollectionViewCell, asset: PHAsset) {
        guard let cell = cell as? InProgressProductImageCollectionViewCell else {
            fatalError()
        }

        cell.imageView.contentMode = .center
        cell.imageView.image = .productsTabProductCellPlaceholderImage

        productImagesProvider.requestImage(asset: asset, targetSize: cell.bounds.size) { [weak cell] image in
            cell?.imageView.contentMode = .scaleAspectFit
            cell?.imageView.image = image
        }
    }

}

enum ProductImagesItem {
    case image(status: ProductImageStatus)
    case addImage
    case extendedAddImage

    var reuseIdentifier: String {
        switch self {
        case .image(let status):
            switch status {
            case .remote:
                return ProductImageCollectionViewCell.reuseIdentifier
            case .uploading:
                return InProgressProductImageCollectionViewCell.reuseIdentifier
            }
        case .addImage:
            return AddProductImageCollectionViewCell.reuseIdentifier
        case .extendedAddImage:
            return ExtendedAddProductImageCollectionViewCell.reuseIdentifier
        }
    }
}

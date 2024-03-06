import Photos
import UIKit
import Kingfisher
import Yosemite

final class ProductImagesCollectionViewDataSource: NSObject {
    private let viewModel: ProductImagesHeaderViewModel
    private let productUIImageLoader: ProductUIImageLoader

    init(viewModel: ProductImagesHeaderViewModel,
         productUIImageLoader: ProductUIImageLoader) {
        self.viewModel = viewModel
        self.productUIImageLoader = productUIImageLoader
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
        case .extendedAddImage(let isVariation):
            if let cell = cell as? ExtendedAddProductImageCollectionViewCell {
                cell.configurePlaceholderLabelForProductImages(isVariation: isVariation)
            }
        default:
            break
        }
    }

    func configureImageCell(_ cell: UICollectionViewCell, productImageStatus: ProductImageStatus) {
        switch productImageStatus {
        case .remote(let image):
            configureRemoteImageCell(cell, productImage: image)
        case .uploading(let asset):
            switch asset {
                case .phAsset(let asset):
                    configureUploadingImageCell(cell, asset: asset)
                case .uiImage(let image, _, _):
                    configureUploadingImageCell(cell, image: image)
            }
        }
    }

    func configureRemoteImageCell(_ cell: UICollectionViewCell, productImage: ProductImage) {
        guard let cell = cell as? ProductImageCollectionViewCell else {
            fatalError()
        }

        cell.imageView.contentMode = .center
        cell.imageView.image = .productsTabProductCellPlaceholderImage
        cell.cancellableTask = Task { @MainActor [weak self, weak cell] in
            guard let image = try? await self?.productUIImageLoader.requestImage(productImage: productImage) else {
                return
            }

            /// `ProductImageCollectionViewCell` cancels the task while preparing the cell for reuse
            /// Checking Task cancellation status prevents us from showing the downloaded image in a different product's cell
            ///
            guard !Task.isCancelled else {
                return
            }
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

        productUIImageLoader.requestImage(asset: asset, targetSize: cell.bounds.size) { [weak cell] image in
            cell?.imageView.contentMode = .scaleAspectFit
            cell?.imageView.image = image
        }
    }

    func configureUploadingImageCell(_ cell: UICollectionViewCell, image: UIImage) {
        guard let cell = cell as? InProgressProductImageCollectionViewCell else {
            fatalError()
        }

        cell.imageView.contentMode = .scaleAspectFit
        cell.imageView.image = image
    }
}

enum ProductImagesItem {
    case image(status: ProductImageStatus)
    case addImage
    case extendedAddImage(isVariation: Bool)

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

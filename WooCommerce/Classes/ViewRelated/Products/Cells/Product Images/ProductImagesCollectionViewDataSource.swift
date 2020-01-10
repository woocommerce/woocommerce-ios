import UIKit
import Kingfisher

final class ProductImagesCollectionViewDataSource: NSObject {
    private let viewModel: ProductImagesViewModel
    private let imageService: ImageService

    init(viewModel: ProductImagesViewModel,
         imageService: ImageService = ServiceLocator.imageService) {
        self.viewModel = viewModel
        self.imageService = imageService
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
            configureImageCell(collectionView: collectionView, cell: cell, at: indexPath, imageService: imageService)
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
    func configureImageCell(collectionView: UICollectionView,
                            cell: ProductImageCollectionViewCell,
                            at indexPath: IndexPath,
                            imageService: ImageService) {
        let image = viewModel.product.images[indexPath.item]

        imageService.downloadAndCacheImageForImageView(cell.imageView,
                                                       with: image.src,
                                                       placeholder: .productPlaceholderImage,
                                                       progressBlock: nil) { (image, error) in
                                                        let success = image != nil && error == nil
                                                        if success {
                                                            cell.imageView.contentMode = .scaleAspectFit
                                                        }
                                                        else {
                                                            cell.imageView.contentMode = .center
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

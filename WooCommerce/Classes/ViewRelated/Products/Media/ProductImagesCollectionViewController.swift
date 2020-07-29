import Photos
import UIKit
import Yosemite

/// Displays Product images in grid layout.
///
final class ProductImagesCollectionViewController: UICollectionViewController {

    private var productImageStatuses: [ProductImageStatus]

    private let productUIImageLoader: ProductUIImageLoader
    private let onDeletion: ProductImageViewController.Deletion

    init(imageStatuses: [ProductImageStatus],
         productUIImageLoader: ProductUIImageLoader,
         onDeletion: @escaping ProductImageViewController.Deletion) {
        self.productImageStatuses = imageStatuses
        self.productUIImageLoader = productUIImageLoader
        self.onDeletion = onDeletion
        let columnLayout = ColumnFlowLayout(
            cellsPerRow: 2,
            minimumInteritemSpacing: 16,
            minimumLineSpacing: 16,
            sectionInset: UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
        )
        super.init(collectionViewLayout: columnLayout)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionView.backgroundColor = .basicBackground

        collectionView.register(ProductImageCollectionViewCell.loadNib(), forCellWithReuseIdentifier: ProductImageCollectionViewCell.reuseIdentifier)
        collectionView.register(InProgressProductImageCollectionViewCell.loadNib(),
                                forCellWithReuseIdentifier: InProgressProductImageCollectionViewCell.reuseIdentifier)

        collectionView.reloadData()
    }

    func updateProductImageStatuses(_ productImageStatuses: [ProductImageStatus]) {
        self.productImageStatuses = productImageStatuses

        collectionView.reloadData()
    }
}

// MARK: UICollectionViewDataSource
//
extension ProductImagesCollectionViewController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productImageStatuses.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let productImageStatus = productImageStatuses[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: productImageStatus.cellReuseIdentifier,
                                                      for: indexPath)
        configureCell(cell, productImageStatus: productImageStatus)
        return cell
    }
}

// MARK: Cell configurations
//
private extension ProductImagesCollectionViewController {
    func configureCell(_ cell: UICollectionViewCell, productImageStatus: ProductImageStatus) {
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

        let cancellable = productUIImageLoader.requestImage(productImage: productImage) { [weak cell] image in
            cell?.imageView.contentMode = .scaleAspectFit
            cell?.imageView.image = image
        }
        cell.cancellableTask = cancellable
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
}

// MARK: UICollectionViewDelegate
//
extension ProductImagesCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let status = productImageStatuses[indexPath.row]
        switch status {
        case .remote:
            break
        default:
            return
        }

        let productImages: [ProductImage] = productImageStatuses.compactMap {
            switch $0 {
            case .remote(let image):
                return image
            default:
                return nil
            }
        }
        let productImagesGalleryViewController = ProductImagesGalleryViewController(images: productImages,
                                                                                    productUIImageLoader: productUIImageLoader) { [weak self] (productImage) in
                                                                                        self?.onDeletion(productImage)
        }
        navigationController?.pushViewController(productImagesGalleryViewController, animated: true)
    }
}

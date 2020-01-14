import UIKit
import Yosemite

/// Displays Product images in grid layout.
///
final class ProductImagesCollectionViewController: UICollectionViewController {

    private var productImages: [ProductImage]

    private let imageService: ImageService
    private let onDeletion: ProductImageViewController.Deletion

    init(images: [ProductImage],
         imageService: ImageService = ServiceLocator.imageService,
         onDeletion: @escaping ProductImageViewController.Deletion) {
        self.productImages = images
        self.imageService = imageService
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

        collectionView.reloadData()
    }

    func updateProductImages(_ productImages: [ProductImage]) {
        self.productImages = productImages

        collectionView.reloadData()
    }
}

// MARK: UICollectionViewDataSource
//
extension ProductImagesCollectionViewController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return productImages.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductImageCollectionViewCell.reuseIdentifier,
                                                            for: indexPath) as? ProductImageCollectionViewCell else {
                                                                fatalError()
        }

        let productImage = productImages[indexPath.row]

        imageService.downloadAndCacheImageForImageView(cell.imageView,
                                                       with: productImage.src,
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

        return cell
    }
}

// MARK: UICollectionViewDelegate
//
extension ProductImagesCollectionViewController {
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let productImage = productImages[indexPath.row]
        let productImageViewController = ProductImageViewController(productImage: productImage, onDeletion: onDeletion)
        navigationController?.pushViewController(productImageViewController, animated: true)
    }
}

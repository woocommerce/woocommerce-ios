import Photos
import Yosemite

/// The status of a Product image.
///
enum ProductImageStatus {
    /// A `PHAsset` is being uploaded.
    ///
    case uploading(asset: PHAsset)

    /// The Product image exists remotely.
    ///
    case remote(image: ProductImage)
}

extension Collection where Element == ProductImageStatus {
    var images: [ProductImage] {
        compactMap { status in
            switch status {
            case .remote(let productImage):
                return productImage
            default:
                return nil
            }
        }
    }
}

extension ProductImageStatus {
    var cellReuseIdentifier: String {
        return cellClass.reuseIdentifier
    }

    private var cellClass: UICollectionViewCell.Type {
        switch self {
        case .uploading:
            return InProgressProductImageCollectionViewCell.self
        case .remote:
            return ProductImageCollectionViewCell.self
        }
    }
}

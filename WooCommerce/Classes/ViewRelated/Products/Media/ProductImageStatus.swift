import Photos
import Yosemite

/// The status of a Product image.
///
enum ProductImageStatus: Equatable {
    /// A `PHAsset` is being uploaded.
    ///
    case uploading(asset: PHAsset)

    /// A `UIImage` is being uploaded.
    ///
    case uploadingImage(image: UIImage)

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

    /// Whether there are still any images being uploaded.
    ///
    var hasPendingUpload: Bool {
        return contains(where: {
            switch $0 {
            case .uploading:
                return true
            default:
                return false
            }
        })
    }
}

extension ProductImageStatus {
    var cellReuseIdentifier: String {
        return cellClass.reuseIdentifier
    }

    private var cellClass: UICollectionViewCell.Type {
        switch self {
        case .uploading, .uploadingImage:
            return InProgressProductImageCollectionViewCell.self
        case .remote:
            return ProductImageCollectionViewCell.self
        }
    }

    /// A string that uniquely identifies a `ProductImageStatus` during
    /// dragging.
    ///
    var dragItemIdentifier: String {
        switch self {
        case .uploading(let asset):
            return asset.identifier()
        case .uploadingImage(let image):
            // TODO-jc
            return image.description
        case .remote(let image):
            return "\(image.imageID)"
        }
    }
}

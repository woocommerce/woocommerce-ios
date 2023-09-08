import Photos
import Yosemite

/// The status of a Product image.
///
enum ProductImageStatus: Equatable {
    /// An image asset is being uploaded.
    ///
    case uploading(asset: ProductImageAssetType)

    /// The Product image exists remotely.
    ///
    case remote(image: ProductImage)
}

/// The type of product image asset.
enum ProductImageAssetType: Equatable {
    /// `PHAsset` from device photo library or camera capture.
    case phAsset(asset: PHAsset)

    /// `UIImage` from image processing. The filename and alt text need to be provided separately.
    case uiImage(image: UIImage, filename: String?, altText: String?)
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
        case .uploading:
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
            switch asset {
                case let .phAsset(asset):
                    return asset.identifier()
                case .uiImage:
                    return UUID().uuidString
            }
        case .remote(let image):
            return "\(image.imageID)"
        }
    }
}

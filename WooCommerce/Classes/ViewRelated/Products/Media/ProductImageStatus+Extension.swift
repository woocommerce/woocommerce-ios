import Photos
import Yosemite

extension Collection where Element == ProductImageStatus {
    var images: [ProductImage] {
        compactMap { status in
            switch status {
            case .remote(let productImage, let siteID, let productID):
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
        case .uploadFailure:
            return FailedProductImageCollectionViewCell.self
        case .remote:
            return ProductImageCollectionViewCell.self
        }
    }

    /// A string that uniquely identifies a `ProductImageStatus` during
    /// dragging.
    ///
    var dragItemIdentifier: String {
        switch self {
        case .uploading(let asset, let siteID, let productID):
            switch asset {
                case let .phAsset(asset):
                    return asset.identifier()
                case .uiImage:
                    return UUID().uuidString
            }
        case .uploadFailure:
            return UUID().uuidString
        case .remote(let image, let siteID, let productID):
            return "\(image.imageID)"
        }
    }
}

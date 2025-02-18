import Foundation
import Photos

/// The status of a Product image.
///
public enum ProductImageStatus: Equatable {
    /// An image asset is being uploaded.
    ///
    case uploading(asset: ProductImageAssetType)

    /// The Product image exists remotely.
    ///
    case remote(image: ProductImage)

    /// An image asset upload failed.
    ///
    case uploadFailure(asset: ProductImageAssetType, error: Error)

    public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.uploading(lAsset), .uploading(rAsset)):
            lAsset == rAsset
        case let (.remote(lImage), .remote(image: rImage)):
            lImage == rImage
        case let (.uploadFailure(lAsset, lError), .uploadFailure(rAsset, rError)):
            lAsset == rAsset && (lError as NSError) == (rError as NSError)
        default:
            false
        }
    }
}

/// The type of product image asset.
public enum ProductImageAssetType: Equatable {
    /// `PHAsset` from device photo library or camera capture.
    case phAsset(asset: PHAsset)

    /// `UIImage` from image processing. The filename and alt text need to be provided separately.
    case uiImage(image: UIImage, filename: String?, altText: String?)
}

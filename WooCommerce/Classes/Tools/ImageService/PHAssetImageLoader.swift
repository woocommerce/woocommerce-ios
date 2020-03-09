import Photos
import UIKit

/// Loads the image of a `PHAsset`.
///
protocol PHAssetImageLoader {
    @discardableResult
    func requestImage(for asset: PHAsset,
                      targetSize: CGSize,
                      contentMode: PHImageContentMode,
                      options: PHImageRequestOptions?,
                      resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID
}

extension PHImageManager: PHAssetImageLoader {}

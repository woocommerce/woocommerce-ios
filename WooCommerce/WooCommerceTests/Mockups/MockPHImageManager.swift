import Photos
import UIKit

final class MockPHImageManager: PHImageManager {
    // Mocks in-memory cache.
    private let imagesByAsset: [PHAsset: UIImage]

    init(imagesByAsset: [PHAsset: UIImage]) {
        self.imagesByAsset = imagesByAsset
    }

    override func requestImage(for asset: PHAsset,
                               targetSize: CGSize,
                               contentMode: PHImageContentMode,
                               options: PHImageRequestOptions?,
                               resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        resultHandler(imagesByAsset[asset], nil)
        return 0
    }
}

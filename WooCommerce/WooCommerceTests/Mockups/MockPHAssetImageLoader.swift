import Photos
import UIKit
@testable import WooCommerce

final class MockPHAssetImageLoader: PHAssetImageLoader {
    // Mocks in-memory cache.
    private let imagesByAsset: [PHAsset: UIImage]
    
    init(imagesByAsset: [PHAsset: UIImage]) {
        self.imagesByAsset = imagesByAsset
    }
    
    func requestImage(for asset: PHAsset,
                      targetSize: CGSize,
                      contentMode: PHImageContentMode,
                      options: PHImageRequestOptions?,
                      resultHandler: @escaping (UIImage?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        resultHandler(imagesByAsset[asset], nil)
        return 0
    }
}

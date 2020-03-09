import Photos
import Yosemite

/// Provides an image for UI display based on the product image status.
///
protocol ProductUIImageLoader {
    /// Requests an image given a remote Product image asynchronously.
    ///
    func requestImage(productImage: ProductImage, completion: @escaping (UIImage) -> Void)

    /// Requests an image given a `PHAsset` asynchronously, with a target size for optimization.
    ///
    func requestImage(asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage) -> Void)
}

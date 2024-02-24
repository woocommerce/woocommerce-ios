import Photos
import Yosemite
import Combine

/// Provides an image for UI display based on the product image status.
///
protocol ProductUIImageLoader {
    /// Requests an image given a remote Product image asynchronously.
    ///
    func requestImage(productImage: ProductImage) async throws -> UIImage

    /// Requests an image given a `PHAsset` asynchronously, with a target size for optimization.
    ///
    func requestImage(asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage) -> Void)

    /// Requests an image given a `PHAsset` asynchronously, with a target size for optimization.
    ///
    /// - Parameters:
    ///   - asset: The asset to generate a `UIImage` from.
    ///   - targetSize: The target size of the image.
    ///   - skipsDegradedImage: Whether to skip the degraded image while loading image from an asset.
    ///   - completion: Invoked when an image is available. Can be called more than once.
    func requestImage(asset: PHAsset, targetSize: CGSize, skipsDegradedImage: Bool, completion: @escaping (UIImage) -> Void)
}

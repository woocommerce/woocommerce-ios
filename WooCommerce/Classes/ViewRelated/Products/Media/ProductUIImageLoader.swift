import Photos
import UIKit
import Yosemite
import Combine

/// Provides an image for UI display based on the product image status.
///
protocol ProductUIImageLoader {
    /// Requests an image given a remote Product image asynchronously.
    ///
    @MainActor
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

    /// Requests an image for a remote Product image with optional size optimization.
    /// - Parameters:
    ///   - productImage: The product image to retrieve.
    ///   - targetSize: Optional target size for image resizing. If provided, the image will be resized to fit within this size while maintaining aspect ratio.
    ///   - completion: Called when the image is available. The completion handler may be called with nil if the image cannot be retrieved.
    /// - Returns: A cancellable task that can be used to cancel the image request.
    /// - Throws: `ImageLoaderError.invalidURL` if the product image URL is invalid.
    func requestImage(
        productImage: ProductImage,
        targetSize: CGSize?,
        completion: @escaping (UIImage?) -> Void
    ) throws -> Cancellable?
}

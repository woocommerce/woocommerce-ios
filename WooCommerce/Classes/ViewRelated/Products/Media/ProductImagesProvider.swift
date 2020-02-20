import Photos
import Yosemite

/// Provides an image for UI display based on the product image status.
///
protocol ProductImagesProvider {
    /// Requests an image given a remote Product image asynchronously.
    ///
    func requestImage(productImage: ProductImage, completion: @escaping (UIImage) -> Void)

    /// Requests an image given a `PHAsset` asynchronously, with a target size for optimization.
    ///
    func requestImage(asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage) -> Void)

    /// Called when an asset has been uploaded to generate an image for UI display.
    /// - Parameters:
    ///   - asset: the asset that has just been uploaded.
    ///   - productImage: the remote product image.
    ///
    func update(from asset: PHAsset, to productImage: ProductImage)
}

import Photos
import Yosemite

/// Provides an image for UI display based on the product image status.
///
protocol ProductImagesProvider {
    func requestImage(productImage: ProductImage, completion: @escaping (UIImage) -> Void)

    func requestImage(asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage) -> Void)

    /// Called when an asset has been uploaded to generate an image for UI display.
    /// - Parameters:
    ///   - asset: the asset that has just been uploaded.
    ///   - productImage: the remote product image.
    ///
    func update(from asset: PHAsset, to productImage: ProductImage)
}

import Photos
import Yosemite

/// Provides images based on Product image status:
/// - Requests the image from `PHImageManager` for a `PHASset`
/// - Downloads the image given the URL of a remote Product image
/// - Caches the images locally for remote Product images
/// - When updating from an asset to remote Product image, caches the asset image locally to avoid an extra API request
///
final class DefaultProductUIImageLoader: ProductUIImageLoader {
    private var imagesByProductImageID: [Int64: UIImage] = [:]
    private let imageService: ImageService
    private let phAssetImageLoader: PHAssetImageLoader

    private let productImagesService: ProductImageActionHandler?

    /// - Parameters:
    ///   - productImagesService: if non-nil, the asset image is used after being uploaded to a remote image to avoid an extra network call.
    ///     Set this property when images are being uploaded in the scope.
    ///   - imageService: provides images given a URL.
    ///   - phAssetImageLoader: provides images given a `PHAsset` asset.
    init(productImagesService: ProductImageActionHandler? = nil,
         imageService: ImageService = ServiceLocator.imageService,
         phAssetImageLoader: PHAssetImageLoader = PHImageManager.default()) {
        self.productImagesService = productImagesService
        self.imageService = imageService
        self.phAssetImageLoader = phAssetImageLoader

        productImagesService?.addAssetUploadObserver(self) { [weak self] asset, productImage in
            self?.update(from: asset, to: productImage)
        }
    }

    func requestImage(productImage: ProductImage, completion: @escaping (UIImage) -> Void) {
        if let image = imagesByProductImageID[productImage.imageID] {
            completion(image)
            return
        }
        guard let url = URL(string: productImage.src) else {
            return
        }
        imageService.downloadImage(with: url, shouldCacheImage: true) { [weak self] (image, error) in
            guard let image = image else {
                return
            }
            self?.imagesByProductImageID[productImage.imageID] = image
            completion(image)
        }
    }

    func requestImage(asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage) -> Void) {
        phAssetImageLoader.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: nil) { (image, info) in
            guard let image = image else {
                return
            }
            completion(image)
        }
    }
}

private extension DefaultProductUIImageLoader {
    func update(from asset: PHAsset, to productImage: ProductImage) {
        phAssetImageLoader.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { [weak self] (image, info) in
            guard let image = image else {
                return
            }
            self?.imagesByProductImageID[productImage.imageID] = image
        }
    }
}

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

    private let productImageActionHandler: ProductImageActionHandler?

    private var activeImageTasks = [ImageDownloadTask]()

    private let phAssetImageLoaderProvider: (() -> PHAssetImageLoader)?
    /// `PHAssetImageLoader` is lazy loaded to avoid triggering permission alert by initializing `PHImageManager` before it is used.
    private lazy var phAssetImageLoader: PHAssetImageLoader = {
        guard let phAssetImageLoaderProvider = phAssetImageLoaderProvider else {
            assertionFailure("Trying to call `PHAssetImageLoader` without setting a provider during initialization")
            return PHImageManager.default()
        }
        return phAssetImageLoaderProvider()
    }()

    /// - Parameters:
    ///   - productImageActionHandler: if non-nil, the asset image is used after being uploaded to a remote image to avoid an extra network call.
    ///     Set this property when images are being uploaded in the scope.
    ///   - imageService: provides images given a URL.
    ///   - phAssetImageLoaderProvider: provides a `PHAssetImageLoader` instance that loads an image given a `PHAsset` asset.
    ///     Only non-nil if `PHAsset` image request is used (e.g. image upload).
    ///     It is a callback because we lazy load `PHAssetImageLoader` to avoid triggering permission alert by initializing `PHImageManager` before it is used.
    init(productImageActionHandler: ProductImageActionHandler? = nil,
         imageService: ImageService = ServiceLocator.imageService,
         phAssetImageLoaderProvider: (() -> PHAssetImageLoader)? = nil) {
        self.productImageActionHandler = productImageActionHandler
        self.imageService = imageService
        self.phAssetImageLoaderProvider = phAssetImageLoaderProvider

        productImageActionHandler?.addAssetUploadObserver(self) { [weak self] asset, productImage in
            self?.update(from: asset, to: productImage)
        }
    }

    deinit {
        activeImageTasks.forEach { $0.cancel() }
        activeImageTasks.removeAll()
    }

    func requestImage(productImage: ProductImage, completion: @escaping (UIImage) -> Void) -> Cancellable? {
        if let image = imagesByProductImageID[productImage.imageID] {
            completion(image)
            return nil
        }
        guard let encodedString = productImage.src.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            return nil
        }
        let task = imageService.downloadImage(with: url, shouldCacheImage: true) { [weak self] (image, error) in
            guard let image = image else {
                return
            }
            self?.imagesByProductImageID[productImage.imageID] = image
            completion(image)
        }
        if let task = task {
            activeImageTasks.append(task)
        }
        return task
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

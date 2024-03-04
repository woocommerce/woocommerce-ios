import Photos
import Yosemite
import Combine

/// Provides images based on Product image status:
/// - Requests the image from `PHImageManager` for a `PHASset`
/// - Downloads the image given the URL of a remote Product image
/// - Caches the images locally for remote Product images
/// - When updating from an asset to remote Product image, caches the asset image locally to avoid an extra API request
///
final class DefaultProductUIImageLoader: ProductUIImageLoader {
    enum ImageLoaderError: Error {
        case invalidURL
        case unableToLoadImage
    }

    private var imageStorage: ImageStorage
    private let imageService: ImageService

    private let productImageActionHandler: ProductImageActionHandler?

    private let phAssetImageLoaderProvider: (() -> PHAssetImageLoader)?
    /// `PHAssetImageLoader` is lazy loaded to avoid triggering permission alert by initializing `PHImageManager` before it is used.
    private lazy var phAssetImageLoader: PHAssetImageLoader = {
        guard let phAssetImageLoaderProvider = phAssetImageLoaderProvider else {
            assertionFailure("Trying to call `PHAssetImageLoader` without setting a provider during initialization")
            return PHImageManager.default()
        }
        return phAssetImageLoaderProvider()
    }()

    private var assetUploadSubscription: AnyCancellable?

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
        self.imageStorage = ImageStorage()

        assetUploadSubscription = productImageActionHandler?.addAssetUploadObserver(self) { [weak self] asset, result in
            guard let self = self else { return }
            guard case let .success(productImage) = result else {
                return
            }
            self.update(from: asset, to: productImage)
        }
    }

    func requestImage(productImage: ProductImage) async throws -> UIImage {
        if let image = await imageStorage.getImage(id: productImage.imageID) {
            return image
        }

        guard let encodedString = productImage.src.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: encodedString) else {
            throw ImageLoaderError.invalidURL
        }

        if let imageFromCache = await withCheckedContinuation({ continuation in
            imageService.retrieveImageFromCache(with: url) { image in
                if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }) {
            return imageFromCache
        }

        if let downloadedImage = await withCheckedContinuation({ continuation in
            _ = imageService.downloadImage(with: url, shouldCacheImage: true) { (image, error) in
                if let image = image {
                    continuation.resume(returning: image)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }) {
            return downloadedImage
        }

        throw ImageLoaderError.unableToLoadImage
    }

    func requestImage(asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage) -> Void) {
        requestImage(asset: asset, targetSize: targetSize, skipsDegradedImage: false, completion: completion)
    }

    func requestImage(asset: PHAsset, targetSize: CGSize, skipsDegradedImage: Bool, completion: @escaping (UIImage) -> Void) {
        phAssetImageLoader.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: nil) { (image, info) in
            guard let image else {
                return
            }
            if let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool, isDegraded && skipsDegradedImage {
                return
            }
            completion(image)
        }
    }
}

private extension DefaultProductUIImageLoader {
    func update(from asset: ProductImageAssetType, to productImage: ProductImage) {
        switch asset {
        case .phAsset(let asset):
            phAssetImageLoader.requestImage(for: asset,
                                            targetSize: PHImageManagerMaximumSize,
                                            contentMode: .aspectFit,
                                            options: nil) { [weak self] (image, info) in
                guard let image, let self else {
                    return
                }
                Task {
                    await self.imageStorage.saveImage(image: image, id: productImage.imageID)
                }
            }
        case .uiImage(let image, _, _):
            Task {
                await imageStorage.saveImage(image: image, id: productImage.imageID)
            }
        }
    }
}

/// Stores images in a dictionary using given `id`
///
private actor ImageStorage {
    private var images: [Int64: UIImage] = [:]

    func saveImage(image: UIImage, id: Int64) {
        images[id] = image
    }

    func getImage(id: Int64) -> UIImage? {
        images[id]
    }
}

import UIKit
import Combine

typealias ImageCacheRetrievalCompletion = (_ image: UIImage?) -> Void
typealias ImageDownloadCompletion = (_ image: UIImage?, _ error: ImageServiceError?) -> Void
typealias ImageDownloadProgressBlock = (_ receivedSize: Int64, _ totalSize: Int64) -> Void

/// Provides an interface for retrieving, downloading, and caching an image.
///
protocol ImageService {

    /// Stores an image directly in the cache.
    /// - Parameters:
    ///   - image: The image to store in cache.
    ///   - url: The URL to use as the cache key.
    func storeImageInCache(_ image: UIImage, for url: URL)

    /// Retrieves an image from cache.
    /// - Parameters:
    ///   - url: url of the image.
    ///   - completion: called when the image is retrieved from cache.
    func retrieveImageFromCache(with url: URL, completion: @escaping ImageCacheRetrievalCompletion)

    /// Downloads an image given a URL.
    /// - Parameters:
    ///   - url: url of the image.
    ///   - shouldCacheImage: whether the downloaded image should be stored in the cache for faster access in the future.
    ///   - completion: called when the image download completes.
    func downloadImage(with url: URL, shouldCacheImage: Bool, completion: ImageDownloadCompletion?) -> ImageDownloadTask?

    /// Downloads and caches an image for a `UIImageView` given a URL and a placeholder.
    /// - Parameters:
    ///   - imageView: `UIImageView` that displays the target image.
    ///   - url: url of the image.
    ///   - placeholder: an optional placeholder image to be displayed before the image is downloaded.
    ///   - targetImageViewSize: whether to resize the image to match the target image view size.
    ///   If true, the image will be resized to fit the image view's dimensions while maintaining aspect ratio.
    ///   - progressBlock: called when the image download progress changes.
    ///   - completion: called when the image download completes.
    func downloadAndCacheImageForImageView(_ imageView: UIImageView,
                                           with url: String?,
                                           placeholder: UIImage?,
                                           progressBlock: ImageDownloadProgressBlock?,
                                           completion: ImageDownloadCompletion?)

    /// Retrieves an image from either cache or network with optional size optimization.
    /// - Parameters:
    ///   - url: URL of the image to retrieve.
    ///   - targetSize: Optional target size for image resizing. If provided, the image will be resized to fit within this size while maintaining aspect ratio.
    ///   - shouldCacheImage: Whether the retrieved image should be stored in the cache for faster access in the future.
    ///   - completion: Called when the image retrieval completes, providing the image and any potential error.
    /// - Returns: A cancellable task that can be used to cancel the image retrieval.
    func retrieveImage(
        with url: URL,
        targetSize: CGSize?,
        shouldCacheImage: Bool,
        completion: ImageDownloadCompletion?
    ) -> Cancellable?

    /// Clears memory cache to reduce memory usage.
    func clearMemoryCache()
}

// MARK: - Errors
//
enum ImageServiceError: Error {
    case other(error: Error)
}

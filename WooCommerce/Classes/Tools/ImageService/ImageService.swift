import UIKit

typealias ImageCacheRetrievalCompletion = (_ image: UIImage?) -> Void
typealias ImageDownloadCompletion = (_ image: UIImage?, _ error: ImageServiceError?) -> Void
typealias ImageDownloadProgressBlock = (_ receivedSize: Int64, _ totalSize: Int64) -> Void

/// Provides an interface for retrieving, downloading, and caching an image.
///
protocol ImageService {

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
    ///   - progressBlock: called when the image download progress changes.
    ///   - completion: called when the image download completes.
    func downloadAndCacheImageForImageView(_ imageView: UIImageView,
                                           with url: String?,
                                           placeholder: UIImage?,
                                           progressBlock: ImageDownloadProgressBlock?,
                                           completion: ImageDownloadCompletion?)
}

// MARK: - Errors
//
enum ImageServiceError: Error {
    case other(error: Error)
}

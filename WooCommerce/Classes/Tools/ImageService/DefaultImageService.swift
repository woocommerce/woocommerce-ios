import Combine
import Foundation
import Kingfisher
import NetworkingCore
import UIKit

private extension URL {
    var imageCacheKey: String {
        return absoluteString
    }
}

/// Implements `ImageService` using `Kingfisher` library.
///
struct DefaultImageService: ImageService {
    private let imageDownloader: ImageDownloader
    private let imageCache: ImageCache

    init(imageCache: ImageCache = ImageCache.optimizedCache,
         imageDownloader: ImageDownloader = Kingfisher.ImageDownloader.default) {
        self.imageCache = imageCache
        self.imageDownloader = imageDownloader
    }

    func retrieveImageFromCache(with url: URL, completion: @escaping ImageCacheRetrievalCompletion) {
        imageCache.retrieveImage(forKey: url.imageCacheKey) { result in
            switch result {
            case .success(let value):
                completion(value.image)
            case .failure(let error):
                DDLogError("Error retriving image from cache: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }

    func downloadImage(with url: URL, shouldCacheImage: Bool, completion: ImageDownloadCompletion?) -> ImageDownloadTask? {
        return imageDownloader.downloadImage(with: Self.httpsURL(from: url)) { result in
                                                switch result {
                                                case .success(let image):
                                                    if shouldCacheImage {
                                                        self.imageCache.store(image, forKey: url.imageCacheKey)
                                                    }

                                                    completion?(image, nil)
                                                case .failure(let kingfisherError):
                                                    Self.logLoadFailure(originalURL: url, error: kingfisherError)
                                                    completion?(nil, .other(error: kingfisherError))
                                                }
        }
    }

    func downloadAndCacheImageForImageView(_ imageView: UIImageView,
                                           with url: String?,
                                           placeholder: UIImage? = nil,
                                           progressBlock: ImageDownloadProgressBlock? = nil,
                                           completion: ImageDownloadCompletion? = nil) {
        let originalURL = Self.encodedURL(from: url)
        let resource = Self.imageResource(from: url)

        let targetSize: CGSize
        if !imageView.bounds.isEmpty {
            let scale = UIScreen.main.scale
            targetSize = CGSize(
                width: imageView.bounds.width * scale,
                height: imageView.bounds.height * scale
            )
        } else {
            targetSize = Constants.defaultThumbnailSize
        }

        let options = buildImageRetrieveOptions(
            targetSize: targetSize,
            shouldCacheImage: true
        )

        imageView.kf.setImage(with: resource,
                              placeholder: placeholder,
                              options: options,
                              progressBlock: progressBlock) { result in
            switch result {
            case .success(let imageResult):
                let image = imageResult.image
                completion?(image, nil)
            case .failure(let error):
                Self.logLoadFailure(originalURL: originalURL, error: error)
                completion?(nil, .other(error: error))
            }
        }
    }

    func retrieveImage(
        with url: URL,
        targetSize: CGSize?,
        shouldCacheImage: Bool,
        completion: ImageDownloadCompletion? = nil
    ) -> Cancellable? {
        let scale = UIScreen.main.scale
        let scaledSize: CGSize?
        if let targetSize {
            scaledSize = CGSize(
                width: targetSize.width * scale,
                height: targetSize.height * scale
            )
        } else {
            scaledSize = nil
        }

        return KingfisherManager.shared.retrieveImage(
            with: Self.httpsResource(for: url),
            options: buildImageRetrieveOptions(
                targetSize: scaledSize,
                shouldCacheImage: shouldCacheImage
            )
        ) { result in
            switch result {
            case .success(let imageResult):
                let image = imageResult.image
                completion?(image, nil)
            case .failure(let error):
                Self.logLoadFailure(originalURL: url, error: error)
                completion?(nil, .other(error: error))
            }
        }
    }

    func clearMemoryCache() {
        imageCache.clearMemoryCache()
    }

    func storeImageInCache(_ image: UIImage, for url: URL) {
        imageCache.store(image, forKey: url.imageCacheKey)
    }

    /// Stores can return `http://` image URLs, which App Transport Security blocks.
    static func imageResource(from string: String?) -> KF.ImageResource? {
        encodedURL(from: string).map(httpsResource(for:))
    }

    /// Keeps `http` for loopback hosts, which ATS allows. The screenshot tool serves images from `http://localhost`.
    static func httpsURL(from url: URL) -> URL {
        if let host = url.host?.lowercased(), Constants.loopbackHosts.contains(host) {
            return url
        }
        return URL(string: url.absoluteString.normalizedToHTTPS()) ?? url
    }

    /// Returns `nil` for cancelled loads, e.g. on cell reuse, and for items without an image URL.
    /// Includes only the host and scheme, as paths and queries can hold private data.
    static func loadFailureDescription(originalURL: URL?, error: Error) -> String? {
        let errorCode: String
        switch error as? KingfisherError {
        case .some(let kingfisherError) where kingfisherError.isTaskCancelled || kingfisherError.isNotCurrentTask:
            return nil
        case .imageSettingError(reason: .emptySource):
            return nil
        case .responseError(reason: .URLSessionError(let sessionError)):
            errorCode = "\((sessionError as NSError).code)"
        case .responseError(reason: .invalidHTTPStatusCode(let response)):
            errorCode = "HTTP \(response.statusCode)"
        default:
            let nsError = error as NSError
            errorCode = "\(nsError.domain) \(nsError.code)"
        }
        let host = originalURL?.host ?? "none"
        let scheme = originalURL?.scheme ?? "none"
        return "Image load failed. Host: \(host), original scheme: \(scheme), error: \(errorCode)"
    }
}

private extension DefaultImageService {
    static func encodedURL(from string: String?) -> URL? {
        let encodedString = string?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return URL(string: encodedString ?? "")
    }

    /// Caches under the caller's URL, so `retrieveImageFromCache` and `storeImageInCache` with that URL still match.
    static func httpsResource(for url: URL) -> KF.ImageResource {
        KF.ImageResource(downloadURL: httpsURL(from: url), cacheKey: url.imageCacheKey)
    }

    static func logLoadFailure(originalURL: URL?, error: Error) {
        guard let description = loadFailureDescription(originalURL: originalURL, error: error) else {
            return
        }
        DDLogError(description)
    }
}

private extension DefaultImageService {
    func buildImageRetrieveOptions(
        targetSize: CGSize?,
        shouldCacheImage: Bool
    ) -> KingfisherOptionsInfo {
        var options: KingfisherOptionsInfo = []

        if let targetSize {
            options.append(
                .processor(
                    DownsamplingImageProcessor(size: targetSize)
                )
            )
        }

        if shouldCacheImage {
            options += [
                .targetCache(imageCache),
                .cacheOriginalImage
            ]
        }

        if let imageDownloader = imageDownloader as? Kingfisher.ImageDownloader {
            options.append(
                .downloader(imageDownloader)
            )
        }

        return options
    }
}

private extension DefaultImageService {
    enum Constants {
        /// A generous size to use for the `DownsamplingImageProcessor`.
        /// The exact ratio isn't important because the library only needs
        /// the higher dimension for creating thumbnails.
        static let defaultThumbnailSize = CGSize(width: 800, height: 800)
        static let loopbackHosts: Set<String> = ["localhost", "127.0.0.1", "::1"]
    }
}

extension ImageCache {
    /// Cache with stricter limit to optimize memory usage.
    ///
    static var optimizedCache: ImageCache {
        let cache = ImageCache.default
        cache.memoryStorage.config.totalCostLimit = 50 * 1024 * 1024 // 50MB
        cache.memoryStorage.config.countLimit = 25
        return cache
    }
}

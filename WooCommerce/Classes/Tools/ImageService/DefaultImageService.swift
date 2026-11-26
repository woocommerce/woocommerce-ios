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
                                                    completion?(nil, .other(error: kingfisherError))
                                                }
        }
    }

    func downloadAndCacheImageForImageView(_ imageView: UIImageView,
                                           with url: String?,
                                           placeholder: UIImage? = nil,
                                           progressBlock: ImageDownloadProgressBlock? = nil,
                                           completion: ImageDownloadCompletion? = nil) {
        let url = Self.imageURL(from: url)

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

        imageView.kf.setImage(with: url,
                              placeholder: placeholder,
                              options: options,
                              progressBlock: progressBlock) { result in
            switch result {
            case .success(let imageResult):
                let image = imageResult.image
                completion?(image, nil)
            case .failure(let error):
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
            with: Self.httpsURL(from: url),
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
    static func imageURL(from string: String?) -> URL? {
        encodedURL(from: string).map(httpsURL(from:))
    }
}

private extension DefaultImageService {
    static func encodedURL(from string: String?) -> URL? {
        let encodedString = string?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        return URL(string: encodedString ?? "")
    }

    static func httpsURL(from url: URL) -> URL {
        URL(string: url.absoluteString.normalizedToHTTPS()) ?? url
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

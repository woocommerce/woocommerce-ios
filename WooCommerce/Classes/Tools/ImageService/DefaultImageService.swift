import Combine
import Foundation
import Kingfisher

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

    /// A generous size to use for the `DownsamplingImageProcessor`.
    /// The exact ratio isn't important because the library only needs
    /// the higher dimension for creating thumbnails.
    private let defaultThumbnailSize = CGSize(width: 800, height: 800)

    /// Options for downloading images
    ///
    private var defaultOptions: KingfisherOptionsInfo {
        return buildImageRetrieveOptions(
            targetSize: defaultThumbnailSize,
            shouldCacheImage: true
        )
    }

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
        return imageDownloader.downloadImage(with: url) { result in
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
        let encodedString = url?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let url = URL(string: encodedString ?? "")
        imageView.kf.setImage(with: url,
                              placeholder: placeholder,
                              options: defaultOptions,
                              progressBlock: progressBlock) { (result) in
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
        return KingfisherManager.shared.retrieveImage(
            with: url,
            options: buildImageRetrieveOptions(
                targetSize: targetSize,
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

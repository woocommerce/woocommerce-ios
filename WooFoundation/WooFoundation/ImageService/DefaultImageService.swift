import Foundation
import Kingfisher

private extension URL {
    var imageCacheKey: String {
        return absoluteString
    }
}

/// Implements `ImageService` using `Kingfisher` library.
///
public struct DefaultImageService: ImageService {
    private let imageDownloader: ImageDownloader
    private let imageCache: ImageCache

    /// A generous size to use for the `DownsamplingImageProcessor`.
    /// The exact ratio isn't important because the library only needs
    /// the higher dimension for creating thumbnails.
    private let defaultThumbnailSize = CGSize(width: 800, height: 800)

    /// Options for downloading images
    ///
    private var defaultOptions: KingfisherOptionsInfo {
        let options: KingfisherOptionsInfo = [
            .targetCache(imageCache),
            .processor(DownsamplingImageProcessor(size: defaultThumbnailSize)),
            .cacheOriginalImage
        ]
        if let imageDownloader = imageDownloader as? Kingfisher.ImageDownloader {
            return options + [.downloader(imageDownloader)]
        }
        return options
    }

    public init(imageCache: ImageCache = ImageCache.default,
                imageDownloader: ImageDownloader = Kingfisher.ImageDownloader.default) {
        self.imageCache = imageCache
        self.imageDownloader = imageDownloader
    }

    public func retrieveImageFromCache(with url: URL, completion: @escaping ImageCacheRetrievalCompletion) {
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

    public func downloadImage(with url: URL, shouldCacheImage: Bool, completion: ImageDownloadCompletion?) -> ImageDownloadTask? {
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

    public func downloadAndCacheImageForImageView(_ imageView: UIImageView,
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
}

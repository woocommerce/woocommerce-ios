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

    private var defaultOptions: KingfisherOptionsInfo {
        return [.targetCache(imageCache), .downloader(imageDownloader)]
    }

    init(imageCache: ImageCache = ImageCache.default,
         imageDownloader: ImageDownloader = ImageDownloader.default) {
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

    func downloadImage(with url: URL, shouldCacheImage: Bool, completion: ImageDownloadCompletion?) {
        imageDownloader.downloadImage(with: url,
                                      options: nil) { result in
                                        switch result {
                                        case .success(let imageResult):
                                            let image = imageResult.image

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
        let url = URL(string: url ?? "")
        imageView.kf.setImage(with: url,
                              placeholder: placeholder,
                              options: defaultOptions,
                              progressBlock: progressBlock) { (result) in
            switch result {
            case .success(let imageResult):
                let image = imageResult.image
                completion?(image, nil)
                break
            case .failure(let error):
                completion?(nil, .other(error: error))
                break
            }
        }
    }

}

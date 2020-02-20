@testable import Kingfisher

final class MockImageDownloader: ImageDownloader {
    // Mocks in-memory cache.
    private let imagesByKey: [String: UIImage]

    init(imagesByKey: [String: UIImage]) {
        self.imagesByKey = imagesByKey
        super.init(name: "Mock!")
    }

    override func downloadImage(with url: URL,
                                options: KingfisherOptionsInfo? = nil,
                                progressBlock: DownloadProgressBlock?,
                                completionHandler: ((Result<ImageLoadingResult, KingfisherError>) -> Void)? = nil) -> DownloadTask? {
        if let image = imagesByKey[url.absoluteString] {
            completionHandler?(.success(.init(image: image, url: url, originalData: Data())))
        } else {
            completionHandler?(.failure(.cacheError(reason: .imageNotExisting(key: url.absoluteString) )))
        }
        return nil
    }

    override func downloadImage(with url: URL,
                                options: KingfisherParsedOptionsInfo,
                                completionHandler: ((Result<ImageLoadingResult, KingfisherError>) -> Void)? = nil) -> DownloadTask? {
        if let image = imagesByKey[url.absoluteString] {
            completionHandler?(.success(.init(image: image, url: url, originalData: Data())))
        } else {
            completionHandler?(.failure(.cacheError(reason: .imageNotExisting(key: url.absoluteString) )))
        }
        return nil
    }
}

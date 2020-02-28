@testable import Kingfisher

final class MockImageCache: ImageCache {
    // Mocks in-memory cache.
    private var imagesByKey: [String: UIImage] = [:]

    override func retrieveImage(forKey key: String,
                                options: KingfisherParsedOptionsInfo,
                                callbackQueue: CallbackQueue = .mainCurrentOrAsync,
                                completionHandler: ((Result<ImageCacheResult, KingfisherError>) -> Void)?) {
        if let image = imagesByKey[key] {
            completionHandler?(.success(.memory(image)))
        } else {
            completionHandler?(.failure(.cacheError(reason: .imageNotExisting(key: key))))
        }
    }

    override func store(_ image: KFCrossPlatformImage,
                        original: Data? = nil,
                        forKey key: String,
                        options: KingfisherParsedOptionsInfo,
                        toDisk: Bool = true,
                        completionHandler: ((CacheStoreResult) -> Void)? = nil) {
        imagesByKey[key] = image
    }

    override func store(_ image: KFCrossPlatformImage,
                        original: Data? = nil,
                        forKey key: String,
                        processorIdentifier identifier: String = "",
                        cacheSerializer serializer: CacheSerializer = DefaultCacheSerializer.default,
                        toDisk: Bool = true,
                        callbackQueue: CallbackQueue = .untouch,
                        completionHandler: ((CacheStoreResult) -> Void)? = nil) {
        imagesByKey[key] = image
    }
}

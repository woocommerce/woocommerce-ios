import XCTest

@testable import WooCommerce
@testable import Kingfisher

final class DefaultImageServiceTests: XCTestCase {
    private let testImage = UIImage.productPlaceholderImage

    private let url = URL(string: "https://woo.com/fun")!

    private var imageService: ImageService!

    override func setUp() {
        super.setUp()

        let mockCache = MockImageCache(name: "Testing")
        let mockDownloader = MockImageDownloader(imagesByKey: [url.absoluteString: testImage])
        imageService = DefaultImageService(imageCache: mockCache, imageDownloader: mockDownloader)
    }

    override func tearDown() {
        imageService.removeAllImagesFromCache()

        super.tearDown()
    }

    func testDownloadingAndCachingAndRetrievingAnImageFromTheSameCache() {
        // Retrieves the image while the cache is empty.
        let waitForRetrievingImageFromEmptyCache = expectation(description: "Wait for retrieving image from an empty cache")
        imageService.retrieveImageFromCache(with: url) { image in
            XCTAssertNil(image)
            waitForRetrievingImageFromEmptyCache.fulfill()
        }

        // Downloads the image and retrieves it again.
        let waitForDownloadingAndCachingAnImage = expectation(description: "Wait for downloading and caching an image")
        let waitForRetrievingImageAfterDownload = expectation(description: "Wait for retrieving image after the previous download")
        let waitForRetrievingImageRemovingAllImagesFromCache = expectation(description: "Wait for retrieving image after removing all images from the cache")
        imageService.downloadImage(with: url, shouldCacheImage: true) { (image, error) in
            XCTAssertNotNil(image)
            waitForDownloadingAndCachingAnImage.fulfill()

            self.imageService.retrieveImageFromCache(with: self.url) { image in
                XCTAssertNotNil(image)
                waitForRetrievingImageAfterDownload.fulfill()

                // Removes all images from cache and then retrieves the image again.
                self.imageService.removeAllImagesFromCache()
                self.imageService.retrieveImageFromCache(with: self.url) { image in
                    XCTAssertNil(image)
                    waitForRetrievingImageRemovingAllImagesFromCache.fulfill()

                    self.imageService.removeAllImagesFromCache()
                }
            }
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testDownloadingAnImageWithoutCaching() {
        // Downloads the image without caching and retrieves it again.
        let waitForDownloadingAndCachingAnImage = expectation(description: "Wait for downloading an image")
        let waitForRetrievingImageAfterDownload = expectation(description: "Wait for retrieving image after the previous download")
        imageService.downloadImage(with: url, shouldCacheImage: false) { (image, error) in
            XCTAssertNotNil(image)
            waitForDownloadingAndCachingAnImage.fulfill()

            self.imageService.retrieveImageFromCache(with: self.url) { image in
                XCTAssertNil(image)
                waitForRetrievingImageAfterDownload.fulfill()
            }
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testDownloadingAndCachingAndRetrievingAnImageForImageView() {
        let mockImageView = UIImageView()
        let mockPlaceholder = UIImage.shippingImage

        // Downloads the image and retrieves it again.
        let waitForDownloadingAndCachingAnImage = expectation(description: "Wait for downloading and caching an image")
        let waitForRetrievingImageAfterDownload = expectation(description: "Wait for retrieving image after the previous download")
        imageService
            .downloadAndCacheImageForImageView(mockImageView,
                                               with: url.absoluteString,
                                               placeholder: mockPlaceholder,
                                               progressBlock: nil) { (image, error) in
                                                XCTAssertNotNil(image)
                                                waitForDownloadingAndCachingAnImage.fulfill()

                                                self.imageService.retrieveImageFromCache(with: self.url) { image in
                                                    XCTAssertNotNil(image)
                                                    waitForRetrievingImageAfterDownload.fulfill()
                                                }
        }
        XCTAssertNotNil(mockImageView.image)

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

}

final private class MockImageCache: ImageCache {
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

    override func clearMemoryCache() {
        imagesByKey = [:]
    }

    override func clearDiskCache(completion handler: (() -> ())? = nil) {
        imagesByKey = [:]
    }
}

final private class MockImageDownloader: ImageDownloader {
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

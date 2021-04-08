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
        _ = imageService.downloadImage(with: url, shouldCacheImage: true) { (image, error) in
            XCTAssertNotNil(image)
            waitForDownloadingAndCachingAnImage.fulfill()

            self.imageService.retrieveImageFromCache(with: self.url) { image in
                XCTAssertNotNil(image)
                waitForRetrievingImageAfterDownload.fulfill()
            }
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testDownloadingAnImageWithoutCaching() {
        // Downloads the image without caching and retrieves it again.
        let waitForDownloadingAndCachingAnImage = expectation(description: "Wait for downloading an image")
        let waitForRetrievingImageAfterDownload = expectation(description: "Wait for retrieving image after the previous download")
        _ = imageService.downloadImage(with: url, shouldCacheImage: false) { (image, error) in
            XCTAssertNotNil(image)
            waitForDownloadingAndCachingAnImage.fulfill()

            self.imageService.retrieveImageFromCache(with: self.url) { image in
                XCTAssertNil(image)
                waitForRetrievingImageAfterDownload.fulfill()
            }
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testCancellingDownloadingAnImage() {
        // Arrange
        let waitForDownloadingAnImage = expectation(description: "Wait for downloading an image")
        let task = imageService.downloadImage(with: url, shouldCacheImage: true) { (image, error) in
            waitForDownloadingAnImage.fulfill()
        }

        guard let mockTask = task as? MockImageDownloadTask else {
            XCTFail("Unexpected download task: \(String(describing: task))")
            return
        }
        XCTAssertFalse(mockTask.isCancelled)

        // Action
        task?.cancel()

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        XCTAssertTrue(mockTask.isCancelled)
    }

    func testDownloadingAndCachingAndRetrievingAnImageForImageView() {
        let mockImageView = UIImageView()
        let mockPlaceholder = UIImage.shippingImage

        let mockCache = MockImageCache(name: "Testing")
        // `MockKingfisherImageDownloader` is used in this test because it depends on a Kingfisher `ImageDownloader`.
        let mockDownloader = MockKingfisherImageDownloader(imagesByKey: [url.absoluteString: testImage])
        imageService = DefaultImageService(imageCache: mockCache, imageDownloader: mockDownloader)

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

    func testDownloadingAndCachingAndRetrievingAnImageForImageViewFromURLWithSpecialChars() {
        let mockImageView = UIImageView()
        let mockPlaceholder = UIImage.shippingImage

        let mockCache = MockImageCache(name: "Testing")

        let urlStringWithSpecialChars = "https://woo.com/тест-图像"
        let encodedURLStringWithSpecialChars = urlStringWithSpecialChars.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let encodedURL = URL(string: encodedURLStringWithSpecialChars)!

        // `MockKingfisherImageDownloader` is used in this test because it depends on a Kingfisher `ImageDownloader`.
        let imagesMapping = [encodedURLStringWithSpecialChars: testImage]
        let mockDownloader = MockKingfisherImageDownloader(imagesByKey: imagesMapping)
        imageService = DefaultImageService(imageCache: mockCache, imageDownloader: mockDownloader)

        // Downloads the image and retrieves it again.
        let waitForDownloadingAndCachingAnImage = expectation(description: "Wait for downloading and caching an image")
        let waitForRetrievingImageAfterDownload = expectation(description: "Wait for retrieving image after the previous download")
        imageService
            .downloadAndCacheImageForImageView(mockImageView,
                                               with: urlStringWithSpecialChars,
                                               placeholder: mockPlaceholder,
                                               progressBlock: nil) { (image, error) in
                XCTAssertNotNil(image)
                waitForDownloadingAndCachingAnImage.fulfill()

                self.imageService.retrieveImageFromCache(with: encodedURL) { image in
                    XCTAssertNotNil(image)
                    waitForRetrievingImageAfterDownload.fulfill()
                }
            }
        XCTAssertNotNil(mockImageView.image)

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

}

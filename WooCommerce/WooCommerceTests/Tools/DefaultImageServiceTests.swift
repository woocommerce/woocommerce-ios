import UIKit
import XCTest

@testable import WooCommerce
@testable import Kingfisher

final class DefaultImageServiceTests: XCTestCase {
    private let testImage = UIImage.productPlaceholderImage

    private let url = URL(string: "https://woocommerce.com/fun")!

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

        let urlStringWithSpecialChars = "https://woocommerce.com/тест-图像"
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

    func test_image_returned_from_cache_on_second_retrieval_when_caching_is_enabled() {
        // Given
        let mockCache = MockImageCache(name: "Testing")
        let mockDownloader = MockKingfisherImageDownloader(imagesByKey: [url.absoluteString: testImage])
        imageService = DefaultImageService(imageCache: mockCache, imageDownloader: mockDownloader)

        // When - First retrieve (should download and cache)
        let waitForFirstRetrieval = expectation(description: "Wait for first image retrieval")
        let waitForSecondRetrieval = expectation(description: "Wait for second image retrieval")

        let task = imageService.retrieveImage(
            with: url,
            targetSize: nil,
            shouldCacheImage: true
        ) { image, error in
            XCTAssertNotNil(image)
            XCTAssertNil(error)

            // Then - Second retrieve (should use cache)
            self.imageService.retrieveImageFromCache(with: self.url) { cachedImage in
                XCTAssertNotNil(cachedImage)
                waitForSecondRetrieval.fulfill()
            }
            waitForFirstRetrieval.fulfill()
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_no_image_returned_from_cache_on_second_retrieval_when_caching_is_disabled() {
        // Given
        let mockCache = MockImageCache(name: "Testing")
        let mockDownloader = MockKingfisherImageDownloader(imagesByKey: [url.absoluteString: testImage])
        imageService = DefaultImageService(imageCache: mockCache, imageDownloader: mockDownloader)

        // When
        let waitForRetrieval = expectation(description: "Wait for image retrieval")
        let waitForCacheCheck = expectation(description: "Wait for cache check")

        let task = imageService.retrieveImage(
            with: url,
            targetSize: nil,
            shouldCacheImage: false
        ) { image, error in
            XCTAssertNotNil(image)
            XCTAssertNil(error)

            // Then - Check cache (should be empty)
            self.imageService.retrieveImageFromCache(with: self.url) { cachedImage in
                XCTAssertNil(cachedImage)
                waitForCacheCheck.fulfill()
            }
            waitForRetrieval.fulfill()
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_retrieved_image_fits_target_size_when_target_size_is_passed() {
        // Given
        let targetSize = CGSize(width: 100, height: 100)
        let mockCache = MockImageCache(name: "Testing")
        let mockDownloader = MockKingfisherImageDownloader(imagesByKey: [url.absoluteString: testImage])
        imageService = DefaultImageService(imageCache: mockCache, imageDownloader: mockDownloader)

        // When
        let waitForRetrieval = expectation(description: "Wait for image retrieval")

        let task = imageService.retrieveImage(
            with: url,
            targetSize: targetSize,
            shouldCacheImage: true
        ) { image, error in
            XCTAssertNotNil(image)
            XCTAssertNil(error)

            // Verify image size
            if let image {
                XCTAssertLessThanOrEqual(image.size.width, targetSize.width)
                XCTAssertLessThanOrEqual(image.size.height, targetSize.height)
                // Check aspect ratio is maintained (with some floating point tolerance)
                let originalAspect = self.testImage.size.width / self.testImage.size.height
                let resizedAspect = image.size.width / image.size.height
                XCTAssertEqual(originalAspect, resizedAspect, accuracy: 0.01)
            }

            waitForRetrieval.fulfill()
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_image_retrieved_when_url_contains_special_characters() {
        // Given
        let urlStringWithSpecialChars = "https://woocommerce.com/тест-图像"
        let encodedURLStringWithSpecialChars = urlStringWithSpecialChars.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let encodedURL = URL(string: encodedURLStringWithSpecialChars)!

        let mockCache = MockImageCache(name: "Testing")
        let mockDownloader = MockKingfisherImageDownloader(imagesByKey: [encodedURLStringWithSpecialChars: testImage])
        imageService = DefaultImageService(imageCache: mockCache, imageDownloader: mockDownloader)

        // When
        let waitForRetrieval = expectation(description: "Wait for image retrieval")

        let task = imageService.retrieveImage(
            with: encodedURL,
            targetSize: nil,
            shouldCacheImage: true
        ) { image, error in
            XCTAssertNotNil(image)
            XCTAssertNil(error)
            waitForRetrieval.fulfill()
        }

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testDownloadAndCacheImageForImageView_withEmptyBounds_usesDefaultThumbnailSize() {
        // Given
        let originalFeatureFlagService = ServiceLocator.featureFlagService
        defer {
            ServiceLocator.setFeatureFlagService(originalFeatureFlagService)
        }

        ServiceLocator.setFeatureFlagService(
            MockFeatureFlagService(
                isProductImageOptimizedHandlingEnabled: true
            )
        )

        let mockImageView = UIImageView(frame: .zero)
        let mockCache = MockImageCache(name: "Testing")
        let mockDownloader = MockKingfisherImageDownloader(imagesByKey: [url.absoluteString: testImage])
        imageService = DefaultImageService(imageCache: mockCache, imageDownloader: mockDownloader)

        // When
        imageService.downloadAndCacheImageForImageView(
            mockImageView,
            with: url.absoluteString,
            placeholder: nil,
            progressBlock: nil,
            completion: nil
        )

        // Then
        guard let downsamplingProcessor = mockDownloader.capturedProcessor as? DownsamplingImageProcessor else {
            XCTFail("DownsamplingImageProcessor not found or not the correct type")
            return
        }

        XCTAssertEqual(downsamplingProcessor.size, CGSize(width: 800, height: 800))
    }
}

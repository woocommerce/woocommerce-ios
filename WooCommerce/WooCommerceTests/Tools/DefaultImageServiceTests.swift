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
        _ = imageService.downloadImage(with: url, shouldCacheImage: true) { image, _ in
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
        _ = imageService.downloadImage(with: url, shouldCacheImage: false) { image, _ in
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
        let task = imageService.downloadImage(with: url, shouldCacheImage: true) { _, _ in
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
                                               progressBlock: nil) { image, _ in
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
                                               progressBlock: nil) { image, _ in
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

    func test_downloadImage_when_url_is_http_then_downloads_https_url() {
        // Given
        let httpURL = URL(string: "http://woocommerce.com/fun")!
        let mockDownloader = MockImageDownloader(imagesByKey: [url.absoluteString: testImage])
        imageService = DefaultImageService(imageCache: MockImageCache(name: "Testing"), imageDownloader: mockDownloader)

        // When
        let waitForDownload = expectation(description: "Wait for downloading an image")
        var downloadedImage: UIImage?
        _ = imageService.downloadImage(with: httpURL, shouldCacheImage: false) { image, _ in
            downloadedImage = image
            waitForDownload.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertNotNil(downloadedImage)
    }

    func test_downloadImage_when_url_is_http_then_caches_under_original_url() {
        // Given
        let httpURL = URL(string: "http://woocommerce.com/fun")!
        let mockDownloader = MockImageDownloader(imagesByKey: [url.absoluteString: testImage])
        imageService = DefaultImageService(imageCache: MockImageCache(name: "Testing"), imageDownloader: mockDownloader)

        // When
        let waitForCacheRetrieval = expectation(description: "Wait for retrieving image from cache")
        var cachedImage: UIImage?
        _ = imageService.downloadImage(with: httpURL, shouldCacheImage: true) { _, _ in
            self.imageService.retrieveImageFromCache(with: httpURL) { image in
                cachedImage = image
                waitForCacheRetrieval.fulfill()
            }
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertNotNil(cachedImage)
    }

    func test_imageURL_when_string_is_http_then_returns_https_url() {
        // When
        let imageURL = DefaultImageService.imageURL(from: "http://woocommerce.com/image.jpg?w=100")

        // Then
        XCTAssertEqual(imageURL?.absoluteString, "https://woocommerce.com/image.jpg?w=100")
    }

    func test_imageURL_when_string_is_http_with_spaces_then_returns_encoded_https_url() {
        // When
        let imageURL = DefaultImageService.imageURL(from: "http://woocommerce.com/my image.jpg")

        // Then
        XCTAssertEqual(imageURL?.absoluteString, "https://woocommerce.com/my%20image.jpg")
    }

    func test_imageURL_when_string_is_https_then_returns_same_url() {
        // When
        let imageURL = DefaultImageService.imageURL(from: "https://woocommerce.com/image.jpg")

        // Then
        XCTAssertEqual(imageURL?.absoluteString, "https://woocommerce.com/image.jpg")
    }

    func test_imageURL_when_string_is_nil_then_returns_nil() {
        // When
        let imageURL = DefaultImageService.imageURL(from: nil)

        // Then
        XCTAssertNil(imageURL)
    }

    func test_loadFailureDescription_when_url_session_error_then_includes_host_and_code() {
        // Given
        let sessionError = NSError(domain: NSURLErrorDomain, code: NSURLErrorAppTransportSecurityRequiresSecureConnection)
        let error = KingfisherError.responseError(reason: .URLSessionError(error: sessionError))

        // When
        let description = DefaultImageService.loadFailureDescription(originalURL: url, error: error)

        // Then
        XCTAssertEqual(description, "Image load failed. Host: woocommerce.com, original scheme: https, error: -1022")
    }

    func test_loadFailureDescription_when_invalid_status_code_then_includes_http_status() {
        // Given
        let response = HTTPURLResponse(url: url, statusCode: 404, httpVersion: nil, headerFields: nil)!
        let error = KingfisherError.responseError(reason: .invalidHTTPStatusCode(response: response))

        // When
        let description = DefaultImageService.loadFailureDescription(originalURL: url, error: error)

        // Then
        XCTAssertEqual(description, "Image load failed. Host: woocommerce.com, original scheme: https, error: HTTP 404")
    }

    func test_loadFailureDescription_when_task_cancelled_then_returns_nil() {
        // Given
        let task = SessionDataTask(task: URLSession.shared.dataTask(with: url))
        let error = KingfisherError.requestError(reason: .taskCancelled(task: task, token: 0))

        // When
        let description = DefaultImageService.loadFailureDescription(originalURL: url, error: error)

        // Then
        XCTAssertNil(description)
    }

    func test_loadFailureDescription_when_not_current_task_then_returns_nil() {
        // Given
        let error = KingfisherError.imageSettingError(reason: .notCurrentSourceTask(result: nil, error: nil, source: .network(url)))

        // When
        let description = DefaultImageService.loadFailureDescription(originalURL: url, error: error)

        // Then
        XCTAssertNil(description)
    }

    func test_loadFailureDescription_when_url_was_http_then_includes_original_scheme() {
        // Given
        let httpURL = URL(string: "http://woocommerce.com/fun")!
        let sessionError = NSError(domain: NSURLErrorDomain, code: NSURLErrorAppTransportSecurityRequiresSecureConnection)
        let error = KingfisherError.responseError(reason: .URLSessionError(error: sessionError))

        // When
        let description = DefaultImageService.loadFailureDescription(originalURL: httpURL, error: error)

        // Then
        XCTAssertEqual(description, "Image load failed. Host: woocommerce.com, original scheme: http, error: -1022")
    }

    func test_loadFailureDescription_when_error_is_not_from_kingfisher_then_includes_domain_and_code() {
        // Given
        let error = NSError(domain: "MockDownloadable", code: 1)

        // When
        let description = DefaultImageService.loadFailureDescription(originalURL: nil, error: error)

        // Then
        XCTAssertEqual(description, "Image load failed. Host: none, original scheme: none, error: MockDownloadable 1")
    }

    func test_loadFailureDescription_then_excludes_path_and_query() throws {
        // Given
        let imageURL = URL(string: "https://woocommerce.com/private/image.jpg?token=secret")!
        let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut)

        // When
        let description = DefaultImageService.loadFailureDescription(originalURL: imageURL, error: error)

        // Then
        let unwrappedDescription = try XCTUnwrap(description)
        XCTAssertEqual(unwrappedDescription, "Image load failed. Host: woocommerce.com, original scheme: https, error: NSURLErrorDomain -1001")
        XCTAssertFalse(unwrappedDescription.contains("private"))
        XCTAssertFalse(unwrappedDescription.contains("token"))
    }
}

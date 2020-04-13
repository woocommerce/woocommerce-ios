import Photos
import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductUIImageLoaderTests: XCTestCase {
    private let testImage = UIImage.productPlaceholderImage

    private let imageURL = URL(string: "https://woo.com/fun")!

    private var imageService: ImageService!

    private let mockProductImageID: Int64 = 134

    override func setUp() {
        super.setUp()

        let mockCache = MockImageCache(name: "Testing")
        let mockDownloader = MockImageDownloader(imagesByKey: [imageURL.absoluteString: testImage])
        imageService = DefaultImageService(imageCache: mockCache, imageDownloader: mockDownloader)
    }

    override func tearDown() {
        imageService = nil
        super.tearDown()
    }

    func testRequestingImageWithRemoteProductImage() {
        let mockPHAssetImageLoader = MockPHAssetImageLoader(imagesByAsset: [:])
        let imageLoader = DefaultProductUIImageLoader(imageService: imageService, phAssetImageLoaderProvider: { mockPHAssetImageLoader })
        let productImage = ProductImage(imageID: mockProductImageID,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: imageURL.absoluteString,
                                        name: "woo",
                                        alt: nil)

        let expectation = self.expectation(description: "Wait for image request")
        imageLoader.requestImage(productImage: productImage) { image in
            XCTAssertEqual(image, self.testImage)
            expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testRequestingImageWithPHAsset() {
        let asset = PHAsset()
        let mockPHAssetImageLoader = MockPHAssetImageLoader(imagesByAsset: [asset: testImage])
        let imageLoader = DefaultProductUIImageLoader(imageService: imageService, phAssetImageLoaderProvider: { mockPHAssetImageLoader })

        let expectation = self.expectation(description: "Wait for image request")
        imageLoader.requestImage(asset: asset, targetSize: .zero) { image in
            XCTAssertEqual(image, self.testImage)
            expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
}

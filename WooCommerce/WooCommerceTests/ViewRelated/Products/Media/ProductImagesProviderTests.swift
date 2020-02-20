import Photos
import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductImagesProviderTests: XCTestCase {
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

    func testRequestingImageWithRemoteProductImage() {
        let imagesProvider = DefaultProductImagesProvider(imageService: imageService)
        let productImage = ProductImage(imageID: mockProductImageID,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: imageURL.absoluteString,
                                        name: "woo",
                                        alt: nil)

        let expectation = self.expectation(description: "Wait for image request")
        imagesProvider.requestImage(productImage: productImage) { image in
            XCTAssertEqual(image, self.testImage)
            expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testRequestingImageWithPHAsset() {
        let asset = PHAsset()
        let mockPHImageManager = MockPHImageManager(imagesByAsset: [asset: testImage])
        let imagesProvider = DefaultProductImagesProvider(imageService: imageService, phImageManager: mockPHImageManager)

        let expectation = self.expectation(description: "Wait for image request")
        imagesProvider.requestImage(asset: asset, targetSize: .zero) { image in
            XCTAssertEqual(image, self.testImage)
            expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testUpdatingPHAssetToRemoteProductImage() {
        let asset = PHAsset()
        let assetImage = UIImage()
        let mockPHImageManager = MockPHImageManager(imagesByAsset: [asset: assetImage])
        let imagesProvider = DefaultProductImagesProvider(imageService: imageService, phImageManager: mockPHImageManager)
        let productImage = ProductImage(imageID: mockProductImageID,
                                        dateCreated: Date(),
                                        dateModified: Date(),
                                        src: imageURL.absoluteString,
                                        name: "woo",
                                        alt: nil)

        let expectation = self.expectation(description: "Wait for image request")

        imagesProvider.update(from: asset, to: productImage)
        imagesProvider.requestImage(productImage: productImage) { image in
            XCTAssertEqual(image, assetImage)
            expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
}

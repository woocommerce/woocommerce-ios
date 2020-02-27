import Photos
import XCTest
@testable import WooCommerce
@testable import Yosemite

extension ProductImageStatus: Equatable {
    public static func == (lhs: ProductImageStatus, rhs: ProductImageStatus) -> Bool {
        switch (lhs, rhs) {
        case let (.remote(lhsImage), .remote(rhsImage)):
            return lhsImage == rhsImage
        case let (.uploading(lhsAsset), .uploading(rhsAsset)):
            return lhsAsset == rhsAsset
        default:
            return false
        }
    }
}

final class ProductImagesServiceTests: XCTestCase {
    func testUploadingMediaSuccessfully() {
        let mockMedia = createMockMedia()
        let mockUploadedProductImage = ProductImage(imageID: mockMedia.mediaID,
                                                    dateCreated: mockMedia.date,
                                                    dateModified: mockMedia.date,
                                                    src: mockMedia.src,
                                                    name: mockMedia.name,
                                                    alt: mockMedia.alt)
        let mockStoresManager = MockMediaStoresManager(media: mockMedia, sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let mockProductImages = [
            ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: ""),
            ProductImage(imageID: 2, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        ]
        let mockRemoteProductImageStatuses = mockProductImages.map { ProductImageStatus.remote(image: $0) }
        let mockProduct = MockProduct().product(images: mockProductImages)

        let productImagesService = ProductImagesService(siteID: 123,
                                                        product: mockProduct)

        let mockAsset = PHAsset()
        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            [.uploading(asset: mockAsset)] + mockRemoteProductImageStatuses,
            [.remote(image: mockUploadedProductImage)] + mockRemoteProductImageStatuses
        ]

        let expectation = self.expectation(description: "Wait for image upload")
        var observedProductImageStatusChanges: [[ProductImageStatus]] = []

        productImagesService.addUpdateObserver(self) { (productImageStatuses, error) in
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedStatusUpdates.count {
                XCTAssertEqual(observedProductImageStatusChanges, expectedStatusUpdates)
                expectation.fulfill()
            }
        }

        productImagesService.uploadMediaAssetToSiteMediaLibrary(asset: mockAsset)

        expectation.expectedFulfillmentCount = 1

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testUploadingMediaUnsuccessfully() {
        let mockStoresManager = MockMediaStoresManager(media: nil, sessionManager: SessionManager.testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let mockProductImages = [
            ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: ""),
            ProductImage(imageID: 2, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        ]
        let mockRemoteProductImageStatuses = mockProductImages.map { ProductImageStatus.remote(image: $0) }
        let mockProduct = MockProduct().product(images: mockProductImages)

        let productImagesService = ProductImagesService(siteID: 123,
                                                        product: mockProduct)

        let mockAsset = PHAsset()
        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            [.uploading(asset: mockAsset)] + mockRemoteProductImageStatuses,
            mockRemoteProductImageStatuses
        ]

        let expectation = self.expectation(description: "Wait for image upload")
        var observedProductImageStatusChanges: [[ProductImageStatus]] = []

        productImagesService.addUpdateObserver(self) { (productImageStatuses, error) in
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedStatusUpdates.count {
                XCTAssertEqual(observedProductImageStatusChanges, expectedStatusUpdates)
                expectation.fulfill()
            }
        }

        productImagesService.uploadMediaAssetToSiteMediaLibrary(asset: mockAsset)

        expectation.expectedFulfillmentCount = 1

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func testDeletingProductImage() {
        let mockProductImages = [
            ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: ""),
            ProductImage(imageID: 2, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        ]
        let mockRemoteProductImageStatuses = mockProductImages.map { ProductImageStatus.remote(image: $0) }
        let mockProduct = MockProduct().product(images: mockProductImages)

        let productImagesService = ProductImagesService(siteID: 123,
                                                        product: mockProduct)

        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            [mockRemoteProductImageStatuses[1]]
        ]

        let expectation = self.expectation(description: "Wait for image upload")
        var observedProductImageStatusChanges: [[ProductImageStatus]] = []

        productImagesService.addUpdateObserver(self) { (productImageStatuses, error) in
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedStatusUpdates.count {
                XCTAssertEqual(observedProductImageStatusChanges, expectedStatusUpdates)
                expectation.fulfill()
            }
        }

        productImagesService.deleteProductImage(mockProductImages[0])

        expectation.expectedFulfillmentCount = 1

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
}

private extension ProductImagesServiceTests {
    func createMockMedia() -> Media {
        return Media(mediaID: 123,
                     date: Date(),
                     fileExtension: "jpg",
                     mimeType: "image/jpeg",
                     src: "wp.com/test.jpg",
                     thumbnailURL: "wp.com/test.jpg",
                     name: "woo",
                     alt: "wc",
                     height: 120,
                     width: 120)
    }
}

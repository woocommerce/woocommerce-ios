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

final class ProductImageActionHandlerTests: XCTestCase {
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

        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: mockProduct)

        let mockAsset = PHAsset()
        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            [.uploading(asset: mockAsset)] + mockRemoteProductImageStatuses,
            [.remote(image: mockUploadedProductImage)] + mockRemoteProductImageStatuses
        ]

        let waitForStatusUpdates = self.expectation(description: "Wait for status updates from image upload")
        waitForStatusUpdates.expectedFulfillmentCount = 1

        var observedProductImageStatusChanges: [[ProductImageStatus]] = []
        productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedStatusUpdates.count {
                waitForStatusUpdates.fulfill()
            }
        }

        let waitForAssetUpload = self.expectation(description: "Wait for asset upload callback from image upload")
        productImageActionHandler.addAssetUploadObserver(self) { (asset, productImage) in
            XCTAssertEqual(asset, mockAsset)
            XCTAssertEqual(productImage, mockUploadedProductImage)
            waitForAssetUpload.fulfill()
        }

        // When
        productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: mockAsset)

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(observedProductImageStatusChanges, expectedStatusUpdates)
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

        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: mockProduct)

        let mockAsset = PHAsset()
        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            [.uploading(asset: mockAsset)] + mockRemoteProductImageStatuses,
            mockRemoteProductImageStatuses
        ]

        let expectation = self.expectation(description: "Wait for image upload")
        expectation.expectedFulfillmentCount = 1

        var observedProductImageStatusChanges: [[ProductImageStatus]] = []
        productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedStatusUpdates.count {
                expectation.fulfill()
            }
        }

        // When
        productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: mockAsset)

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(observedProductImageStatusChanges, expectedStatusUpdates)
    }

    func testDeletingProductImage() {
        let mockProductImages = [
            ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: ""),
            ProductImage(imageID: 2, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        ]
        let mockRemoteProductImageStatuses = mockProductImages.map { ProductImageStatus.remote(image: $0) }
        let mockProduct = MockProduct().product(images: mockProductImages)

        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: mockProduct)

        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            [mockRemoteProductImageStatuses[1]]
        ]

        let expectation = self.expectation(description: "Wait for image upload")
        expectation.expectedFulfillmentCount = 1

        var observedProductImageStatusChanges: [[ProductImageStatus]] = []
        productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedStatusUpdates.count {
                expectation.fulfill()
            }
        }

        // When
        productImageActionHandler.deleteProductImage(mockProductImages[0])

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(observedProductImageStatusChanges, expectedStatusUpdates)
    }

    // MARK: - `addSiteMediaLibraryImagesToProduct(mediaItems:)`

    func testAddingProductImagesFromSiteMediaLibrary() {
        // Arrange
        let mockProductImages = [
            ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: ""),
            ProductImage(imageID: 2, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        ]
        let mockRemoteProductImageStatuses = mockProductImages.map { ProductImageStatus.remote(image: $0) }
        let mockProduct = MockProduct().product(images: mockProductImages)

        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: mockProduct)

        // Act
        let mockMedia1 = Media(mediaID: 134, date: Date(),
                               fileExtension: "jpg", mimeType: "image/jpeg",
                               src: "pic", thumbnailURL: "https://test.com/pic1",
                               name: "pic1", alt: "the first image",
                               height: 136, width: 120)
        let mockMedia2 = Media(mediaID: 990, date: Date(),
                               fileExtension: "png", mimeType: "image/png",
                               src: "woo", thumbnailURL: "https://test.com/woo",
                               name: "woo", alt: "the second image",
                               height: 320, width: 776)
        let mockMediaItems = [mockMedia1, mockMedia2]
        productImageActionHandler.addSiteMediaLibraryImagesToProduct(mediaItems: mockMediaItems)

        // Assert
        let expectedImageStatusesFromSiteMediaLibrary = mockMediaItems.map { ProductImageStatus.remote(image: $0.toProductImage) }
        let expectedImageStatuses = expectedImageStatusesFromSiteMediaLibrary + mockRemoteProductImageStatuses

        let expectation = self.expectation(description: "Wait for image statuses")
        expectation.expectedFulfillmentCount = 1

        productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            XCTAssertEqual(productImageStatuses, expectedImageStatuses)
            expectation.fulfill()
        }
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }
}

private extension ProductImageActionHandlerTests {
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

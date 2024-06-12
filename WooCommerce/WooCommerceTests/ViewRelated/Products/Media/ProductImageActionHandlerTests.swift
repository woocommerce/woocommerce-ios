import Combine
import Photos
import TestKit
import XCTest
@testable import WooCommerce
@testable import Yosemite

final class ProductImageActionHandlerTests: XCTestCase {
    private var productImageStatusesSubscription: AnyCancellable?
    private var assetUploadSubscription: AnyCancellable?

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
        let mockProduct = Product.fake().copy(images: mockProductImages)

        let model = EditableProductModel(product: mockProduct)
        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: model)

        let mockAsset = PHAsset()
        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            [.uploading(asset: .phAsset(asset: mockAsset))] + mockRemoteProductImageStatuses,
            [.remote(image: mockUploadedProductImage)] + mockRemoteProductImageStatuses
        ]

        let waitForStatusUpdates = self.expectation(description: "Wait for status updates from image upload")
        waitForStatusUpdates.expectedFulfillmentCount = 1

        var observedProductImageStatusChanges: [[ProductImageStatus]] = []
        productImageStatusesSubscription = productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            XCTAssertTrue(Thread.current.isMainThread)
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedStatusUpdates.count {
                waitForStatusUpdates.fulfill()
            }
        }

        let waitForAssetUpload = self.expectation(description: "Wait for asset upload callback from image upload")
        assetUploadSubscription = productImageActionHandler.addAssetUploadObserver(self) { (asset, result) in
            guard case let .success(productImage) = result else {
                return XCTFail()
            }
            XCTAssertTrue(Thread.current.isMainThread)
            XCTAssertEqual(asset, .phAsset(asset: mockAsset))
            XCTAssertEqual(productImage, mockUploadedProductImage)
            waitForAssetUpload.fulfill()
        }

        // When
        productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: mockAsset))

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
        let mockProduct = Product.fake().copy(images: mockProductImages)

        let model = EditableProductModel(product: mockProduct)
        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: model)

        let mockAsset = PHAsset()
        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            [.uploading(asset: .phAsset(asset: mockAsset))] + mockRemoteProductImageStatuses,
            mockRemoteProductImageStatuses
        ]

        let expectation = self.expectation(description: "Wait for image upload")
        expectation.expectedFulfillmentCount = 1

        var observedProductImageStatusChanges: [[ProductImageStatus]] = []
        productImageStatusesSubscription = productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            XCTAssertTrue(Thread.current.isMainThread)
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedStatusUpdates.count {
                expectation.fulfill()
            }
        }

        // When
        productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: mockAsset))

        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)

        // Then
        XCTAssertEqual(observedProductImageStatusChanges, expectedStatusUpdates)
    }

    func test_uploading_UIImage_passes_filename_and_altText_to_MediaAction() {
        // Given
        let mockStoresManager = MockStoresManager(sessionManager: .testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let model = EditableProductModel(product: .fake())
        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: model)

        // When
        let mediaMetadata: (filename: String?, altText: String?) = waitFor { promise in
            mockStoresManager.whenReceivingAction(ofType: MediaAction.self) { action in
                guard case let .uploadMedia(_, _, mediaAsset, altText, filename, _) = action else {
                    return XCTFail("Unexpected media action: \(action)")
                }
                XCTAssertTrue(mediaAsset is UIImage)
                promise((filename: filename, altText: altText))
            }

            productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .uiImage(image: .init(), filename: "woocommerce.jpg", altText: "cool product"))
        }

        // Then
        XCTAssertEqual(mediaMetadata.filename, "woocommerce.jpg")
        XCTAssertEqual(mediaMetadata.altText, "cool product")
    }

    func test_uploading_UIImage_adds_uploading_status_with_UIImage_asset_type() {
        // Given
        let mockStoresManager = MockStoresManager(sessionManager: .testingInstance)
        ServiceLocator.setStores(mockStoresManager)

        let model = EditableProductModel(product: .fake())
        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: model)
        let mockImage = UIImage()

        // When
        let statuses: [ProductImageStatus] = waitFor { promise in
            productImageActionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .uiImage(image: mockImage, filename: "woocommerce.jpg", altText: "cool product"))
            self.productImageStatusesSubscription = productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
                XCTAssertTrue(Thread.current.isMainThread)
                promise(productImageStatuses)
            }
        }

        // Then
        assertEqual(statuses, [.uploading(asset: .uiImage(image: mockImage, filename: "woocommerce.jpg", altText: "cool product"))])
    }

    func testDeletingProductImage() {
        let mockProductImages = [
            ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: ""),
            ProductImage(imageID: 2, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        ]
        let mockRemoteProductImageStatuses = mockProductImages.map { ProductImageStatus.remote(image: $0) }
        let mockProduct = Product.fake().copy(images: mockProductImages)

        let model = EditableProductModel(product: mockProduct)
        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: model)

        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            [mockRemoteProductImageStatuses[1]]
        ]

        let expectation = self.expectation(description: "Wait for image upload")
        expectation.expectedFulfillmentCount = 1

        var observedProductImageStatusChanges: [[ProductImageStatus]] = []
        productImageStatusesSubscription = productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            XCTAssertTrue(Thread.current.isMainThread)
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
        let mockProduct = Product.fake().copy(images: mockProductImages)

        let model = EditableProductModel(product: mockProduct)
        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: model)

        // Media items to upload to site media library.
        let mockMedia1 = Media(mediaID: 134, date: Date(),
                               fileExtension: "jpg", filename: "pic1.jpg", mimeType: "image/jpeg",
                               src: "pic", thumbnailURL: "https://test.com/pic1",
                               name: "pic1", alt: "the first image",
                               height: 136, width: 120)
        let mockMedia2 = Media(mediaID: 990, date: Date(),
                               fileExtension: "png", filename: "pic2.png", mimeType: "image/png",
                               src: "woo", thumbnailURL: "https://test.com/woo",
                               name: "woo", alt: "the second image",
                               height: 320, width: 776)
        let mockMediaItems = [mockMedia1, mockMedia2]

        let expectedImageStatusesFromSiteMediaLibrary = mockMediaItems.map { ProductImageStatus.remote(image: $0.toProductImage) }
        let expectedStatusUpdates: [[ProductImageStatus]] = [
            mockRemoteProductImageStatuses,
            expectedImageStatusesFromSiteMediaLibrary + mockRemoteProductImageStatuses
        ]

        let expectation = self.expectation(description: "Wait for image upload")
        expectation.expectedFulfillmentCount = 1

        var observedProductImageStatusChanges: [[ProductImageStatus]] = []
        productImageStatusesSubscription = productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            XCTAssertTrue(Thread.current.isMainThread)
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedStatusUpdates.count {
                expectation.fulfill()
            }
        }

        // Act
        productImageActionHandler.addSiteMediaLibraryImagesToProduct(mediaItems: mockMediaItems)

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertEqual(observedProductImageStatusChanges, expectedStatusUpdates)
    }

    // MARK: - `resetProductImages(to:)`

    func testResettingProductImagesToAProduct() {
        // Arrange
        let mockProduct = Product.fake().copy(images: [])
        let model = EditableProductModel(product: mockProduct)
        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: model)
        let mockProductImages = [
            ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: ""),
            ProductImage(imageID: 2, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        ]
        let anotherMockProduct = Product.fake().copy(images: mockProductImages)
        let anotherModel = EditableProductModel(product: anotherMockProduct)

        let expectedProductImageStatuses = mockProductImages.map { ProductImageStatus.remote(image: $0) }

        let expectation = self.expectation(description: "Wait for reset product images")
        expectation.expectedFulfillmentCount = 1

        var observedProductImageStatusChanges: [[ProductImageStatus]] = []
        productImageStatusesSubscription = productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            XCTAssertTrue(Thread.current.isMainThread)
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedProductImageStatuses.count {
                expectation.fulfill()
            }
        }

        // Action
        productImageActionHandler.resetProductImages(to: anotherModel)

        // Assert
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertEqual(productImageActionHandler.productImageStatuses, expectedProductImageStatuses)
    }

    // MARK: - `updateProductImageStatusesAfterReordering

    func test_productImageStatuses_are_updated_correctly_after_reordering() {
        // Given
        let mockProduct = Product.fake().copy(images: [])
        let model = EditableProductModel(product: mockProduct)
        let productImageActionHandler = ProductImageActionHandler(siteID: 123,
                                                                  product: model)
        let mockProductImages = [
            ProductImage(imageID: 1, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: ""),
            ProductImage(imageID: 2, dateCreated: Date(), dateModified: Date(), src: "", name: "", alt: "")
        ]
        let anotherMockProduct = Product.fake().copy(images: mockProductImages)
        let expectedProductImageStatuses = mockProductImages.map { ProductImageStatus.remote(image: $0) }

        let expectation = self.expectation(description: "Wait for update product images")
        expectation.expectedFulfillmentCount = 1

        var observedProductImageStatusChanges: [[ProductImageStatus]] = []
        productImageStatusesSubscription = productImageActionHandler.addUpdateObserver(self) { (productImageStatuses, error) in
            XCTAssertTrue(Thread.current.isMainThread)
            observedProductImageStatusChanges.append(productImageStatuses)
            if observedProductImageStatusChanges.count >= expectedProductImageStatuses.count {
                expectation.fulfill()
            }
        }

        // When
        productImageActionHandler.updateProductImageStatusesAfterReordering(anotherMockProduct.imageStatuses)

        // Then
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertEqual(productImageActionHandler.productImageStatuses, expectedProductImageStatuses)
    }
}

private extension ProductImageActionHandlerTests {
    func createMockMedia() -> Media {
        return Media(mediaID: 123,
                     date: Date(),
                     fileExtension: "jpg",
                     filename: "test.jpg",
                     mimeType: "image/jpeg",
                     src: "wp.com/test.jpg",
                     thumbnailURL: "wp.com/test.jpg",
                     name: "woo",
                     alt: "wc",
                     height: 120,
                     width: 120)
    }
}

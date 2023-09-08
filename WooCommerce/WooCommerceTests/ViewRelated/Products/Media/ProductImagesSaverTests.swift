@testable import WooCommerce
import Combine
import Photos
import XCTest
import Yosemite

final class ProductImagesSaverTests: XCTestCase {
    private let siteID: Int64 = 134
    private let productID: Int64 = 606

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()

        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        analytics = nil
        analyticsProvider = nil

        super.tearDown()
    }

    func test_image_status_with_upload_error_is_removed_from_imageStatusesToSave() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let actionHandler = ProductImageActionHandler(siteID: siteID, productID: .product(id: productID), imageStatuses: [], stores: stores)
        let asset: ProductImageAssetType = .phAsset(asset: PHAsset())
        let imagesSaver = ProductImagesSaver(siteID: siteID, productOrVariationID: .product(id: productID), stores: stores)

        // Uploads an image and waits for the image upload completion closure to be called later.
        let imageUploadCompletion: ((Result<Media, Error>) -> Void) = waitFor { promise in
            stores.whenReceivingAction(ofType: MediaAction.self) { action in
                if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                    promise(onCompletion)
                }
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        }

        // Saves product images.
        imagesSaver.saveProductImagesWhenNoneIsPendingUploadAnymore(imageActionHandler: actionHandler) { _ in }
        XCTAssertEqual(imagesSaver.imageStatusesToSave, [.uploading(asset: asset)])

        // When
        imageUploadCompletion(.failure(MediaActionError.unknown))

        waitForImageStatusesUpdate(actionHandler: actionHandler)

        // Then
        XCTAssertEqual(imagesSaver.imageStatusesToSave, [])
    }

    func test_imageStatusesToSave_stays_empty_after_saving_product_successfully() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let actionHandler = ProductImageActionHandler(siteID: siteID, productID: .product(id: productID), imageStatuses: [], stores: stores)
        let asset: ProductImageAssetType = .phAsset(asset: PHAsset())
        let imagesSaver = ProductImagesSaver(siteID: siteID, productOrVariationID: .product(id: productID), stores: stores)

        // Mocks successful product images update.
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, images, onCompletion) = action {
                onCompletion(.success(.fake().copy(images: images)))
            }
        }

        // Uploads an image and waits for the image upload completion closure to be called later.
        let imageUploadCompletion: ((Result<Media, Error>) -> Void) = waitFor { promise in
            stores.whenReceivingAction(ofType: MediaAction.self) { action in
                if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                    promise(onCompletion)
                }
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        }

        let _: Void = waitFor { promise in
            // Saves product images.
            imagesSaver.saveProductImagesWhenNoneIsPendingUploadAnymore(imageActionHandler: actionHandler) { _ in
                promise(())
            }
            XCTAssertEqual(imagesSaver.imageStatusesToSave, [.uploading(asset: asset)])

            // When
            // Mocks successful image upload.
            imageUploadCompletion(.success(.fake().copy(mediaID: 645)))
        }

        // Then
        XCTAssertEqual(imagesSaver.imageStatusesToSave, [])

        // When
        // Uploads another image.
        let imageUploadCompletionAfterSave: ((Result<Media, Error>) -> Void) = waitFor { promise in
            stores.whenReceivingAction(ofType: MediaAction.self) { action in
                if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                    promise(onCompletion)
                }
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        }
        imageUploadCompletionAfterSave(.success(.fake().copy(mediaID: 606)))

        // Then
        waitForImageStatusesUpdate(actionHandler: actionHandler)
        XCTAssertEqual(imagesSaver.imageStatusesToSave, [])
    }

    func test_imageStatusesToSave_stays_empty_after_saving_product_fails() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let actionHandler = ProductImageActionHandler(siteID: siteID, productID: .product(id: productID), imageStatuses: [], stores: stores)
        let asset: ProductImageAssetType = .phAsset(asset: PHAsset())
        let imagesSaver = ProductImagesSaver(siteID: siteID, productOrVariationID: .product(id: productID), stores: stores)

        // Mocks product images update failure.
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, _, onCompletion) = action {
                onCompletion(.failure(.unexpected))
            }
        }

        // Uploads an image and waits for the image upload completion closure to be called later.
        let imageUploadCompletion: ((Result<Media, Error>) -> Void) = waitFor { promise in
            stores.whenReceivingAction(ofType: MediaAction.self) { action in
                if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                    promise(onCompletion)
                }
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        }

        let _: Void = waitFor { promise in
            // Saves product images.
            imagesSaver.saveProductImagesWhenNoneIsPendingUploadAnymore(imageActionHandler: actionHandler) { _ in
                promise(())
            }
            XCTAssertEqual(imagesSaver.imageStatusesToSave, [.uploading(asset: asset)])

            // Mocks successful image upload.
            imageUploadCompletion(.success(.fake().copy(mediaID: 645)))
        }

        // Then
        XCTAssertEqual(imagesSaver.imageStatusesToSave, [])
    }

    func test_updateProductVariationImage_is_dispatched_when_saving_an_image_to_ProductVariation() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let variationID: ProductOrVariationID = .variation(productID: productID, variationID: 134)
        let imagesSaver = ProductImagesSaver(siteID: siteID, productOrVariationID: variationID, stores: stores)
        let asset: ProductImageAssetType = .phAsset(asset: PHAsset())
        let actionHandler = MockProductImageActionHandler(productImageStatuses: [.uploading(asset: asset)])
        let image = ProductImage.fake()
        actionHandler.assetUploadResults = (asset: asset, result: .success(image))

        // Mocks successful variation image update.
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            if case let .updateProductVariationImage(_, _, _, image, completion) = action {
                completion(.success(.fake().copy(image: image)))
            }
        }

        // When
        let result: Result<[ProductImage], Error> = waitFor { promise in
            // Saves product images.
            imagesSaver.saveProductImagesWhenNoneIsPendingUploadAnymore(imageActionHandler: actionHandler) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertEqual(imagesSaver.imageStatusesToSave, [])
        let savedImages = try XCTUnwrap(result.get())
        XCTAssertEqual(savedImages, [image])
    }

    // MARK: - Analytics

    func test_savingProductAfterBackgroundImageUploadSuccess_is_tracked_on_variation_update_success() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let variationID: ProductOrVariationID = .variation(productID: productID, variationID: 134)
        let imagesSaver = ProductImagesSaver(siteID: siteID, productOrVariationID: variationID, stores: stores, analytics: analytics)
        let asset: ProductImageAssetType = .phAsset(asset: PHAsset())
        let actionHandler = MockProductImageActionHandler(productImageStatuses: [.uploading(asset: asset)])
        let image = ProductImage.fake()
        actionHandler.assetUploadResults = (asset: asset, result: .success(image))

        // Mocks successful variation image update.
        stores.whenReceivingAction(ofType: ProductVariationAction.self) { action in
            if case let .updateProductVariationImage(_, _, _, image, completion) = action {
                completion(.success(.fake().copy(image: image)))
            }
        }

        // When
        waitFor { promise in
            // Saves product images.
            imagesSaver.saveProductImagesWhenNoneIsPendingUploadAnymore(imageActionHandler: actionHandler) { result in
                promise(())
            }
        }

        // Then
        assertEqual([WooAnalyticsStat.savingProductAfterBackgroundImageUploadSuccess.rawValue], analyticsProvider.receivedEvents)
        assertEqual("variation", analyticsProvider.receivedProperties.first?["type"] as? String)
    }

    func test_savingProductAfterBackgroundImageUploadFailed_is_tracked_on_product_update_failure() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imagesSaver = ProductImagesSaver(siteID: siteID, productOrVariationID: .product(id: 648), stores: stores, analytics: analytics)
        let asset: ProductImageAssetType = .phAsset(asset: PHAsset())
        let actionHandler = MockProductImageActionHandler(productImageStatuses: [.uploading(asset: asset)])
        let image = ProductImage.fake()
        actionHandler.assetUploadResults = (asset: asset, result: .success(image))

        // Mocks successful variation image update.
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, _, completion) = action {
                completion(.failure(.unexpected))
            }
        }

        // When
        waitFor { promise in
            // Saves product images.
            imagesSaver.saveProductImagesWhenNoneIsPendingUploadAnymore(imageActionHandler: actionHandler) { result in
                promise(())
            }
        }

        // Then
        assertEqual([WooAnalyticsStat.savingProductAfterBackgroundImageUploadFailed.rawValue], analyticsProvider.receivedEvents)
        assertEqual("product", analyticsProvider.receivedProperties.first?["type"] as? String)
        assertEqual("Yosemite.ProductUpdateError", analyticsProvider.receivedProperties.first?["error_domain"] as? String)
    }
}

private extension ProductImagesSaverTests {
    func waitForImageStatusesUpdate(actionHandler: ProductImageActionHandler) {
        waitFor { promise in
            actionHandler.addUpdateObserver(self) { statuses in
                promise(())
            }
        }
    }
}

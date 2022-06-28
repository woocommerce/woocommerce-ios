@testable import WooCommerce
import Combine
import Photos
import XCTest
import Yosemite

final class ProductImagesSaverTests: XCTestCase {
    private let siteID: Int64 = 134
    private let productID: Int64 = 606

    func test_image_status_with_upload_error_is_removed_from_imageStatusesToSave() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let actionHandler = ProductImageActionHandler(siteID: siteID, productID: productID, imageStatuses: [], stores: stores)
        let asset = PHAsset()
        let imagesSaver = ProductImagesSaver(siteID: siteID, productID: productID, stores: stores)

        // Uploads an image and waits for the image upload completion closure to be called later.
        let imageUploadCompletion: ((Result<Media, Error>) -> Void) = waitFor { promise in
            stores.whenReceivingAction(ofType: MediaAction.self) { action in
                if case let .uploadMedia(_, _, _, onCompletion) = action {
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
        let actionHandler = ProductImageActionHandler(siteID: siteID, productID: productID, imageStatuses: [], stores: stores)
        let asset = PHAsset()
        let imagesSaver = ProductImagesSaver(siteID: siteID, productID: productID, stores: stores)

        // Mocks successful product images update.
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, images, onCompletion) = action {
                onCompletion(.success(.fake().copy(images: images)))
            }
        }

        // Uploads an image and waits for the image upload completion closure to be called later.
        let imageUploadCompletion: ((Result<Media, Error>) -> Void) = waitFor { promise in
            stores.whenReceivingAction(ofType: MediaAction.self) { action in
                if case let .uploadMedia(_, _, _, onCompletion) = action {
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
                if case let .uploadMedia(_, _, _, onCompletion) = action {
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
        let actionHandler = ProductImageActionHandler(siteID: siteID, productID: productID, imageStatuses: [], stores: stores)
        let asset = PHAsset()
        let imagesSaver = ProductImagesSaver(siteID: siteID, productID: productID, stores: stores)

        // Mocks product images update failure.
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, _, onCompletion) = action {
                onCompletion(.failure(.unexpected))
            }
        }

        // Uploads an image and waits for the image upload completion closure to be called later.
        let imageUploadCompletion: ((Result<Media, Error>) -> Void) = waitFor { promise in
            stores.whenReceivingAction(ofType: MediaAction.self) { action in
                if case let .uploadMedia(_, _, _, onCompletion) = action {
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

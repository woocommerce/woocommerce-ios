@testable import WooCommerce
import Photos
import XCTest
import Yosemite

final class ProductImageUploaderTests: XCTestCase {
    private let siteID: Int64 = 134
    private let productID: Int64 = 606

    func test_hasUnsavedChangesOnImages_becomes_false_after_uploading_and_saving() throws {
        // Given
        let imageUploader = ProductImageUploader()
        let actionHandler = imageUploader.actionHandler(siteID: siteID, productID: productID, isLocalID: false, originalStatuses: [])
        let asset = PHAsset()

        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(siteID: siteID, productID: productID, isLocalID: false, originalImages: []))

        // When
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        let statuses = waitFor { promise in
            actionHandler.addUpdateObserver(self) { statuses in
                promise(statuses)
            }
        }
        XCTAssertTrue(statuses.productImageStatuses.hasPendingUpload)
        XCTAssertTrue(imageUploader.hasUnsavedChangesOnImages(siteID: siteID, productID: productID, isLocalID: false, originalImages: []))
        imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(siteID: siteID, productID: productID, isLocalID: false) { _ in }

        // Then
        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(siteID: siteID, productID: productID, isLocalID: false, originalImages: []))
    }

    func test_hasUnsavedChangesOnImages_stays_false_after_uploading_and_saving_successfully() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = ProductImageUploader(stores: stores)
        let actionHandler = imageUploader.actionHandler(siteID: siteID, productID: productID, isLocalID: false, originalStatuses: [])
        let asset = PHAsset()

        let uploadedMedia = Media.fake().copy(mediaID: 645)
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, onCompletion) = action {
                onCompletion(.success(uploadedMedia))
            }
        }
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, images, onCompletion) = action {
                onCompletion(.success(.fake().copy(images: images)))
            }
        }

        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(siteID: siteID, productID: productID, isLocalID: false, originalImages: []))

        // When
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        let statuses = waitFor { promise in
            actionHandler.addUpdateObserver(self) { statuses in
                promise(statuses)
            }
        }
        XCTAssertTrue(statuses.productImageStatuses.hasPendingUpload)
        XCTAssertTrue(imageUploader.hasUnsavedChangesOnImages(siteID: siteID, productID: productID, isLocalID: false, originalImages: []))
        let resultOfSavedImages = waitFor { promise in
            imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(siteID: self.siteID, productID: self.productID, isLocalID: false) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(siteID: siteID, productID: productID, isLocalID: false, originalImages: []))
        XCTAssertTrue(resultOfSavedImages.isSuccess)
        let images = try XCTUnwrap(resultOfSavedImages.get())
        XCTAssertEqual(images.map { $0.imageID }, [uploadedMedia.mediaID])
    }
}

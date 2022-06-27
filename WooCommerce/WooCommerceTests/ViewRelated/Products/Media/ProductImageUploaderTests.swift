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
        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(siteID: siteID,
                                                               productID: productID,
                                                               isLocalID: false,
                                                               originalImages: [.fake().copy(imageID: 645)]))
        XCTAssertTrue(resultOfSavedImages.isSuccess)
        let images = try XCTUnwrap(resultOfSavedImages.get())
        XCTAssertEqual(images.map { $0.imageID }, [uploadedMedia.mediaID])
    }

    func test_when_saving_product_twice_the_latest_images_are_saved() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = ProductImageUploader(stores: stores)
        let actionHandler = imageUploader.actionHandler(siteID: siteID, productID: productID, isLocalID: false, originalStatuses: [])
        let asset = PHAsset()

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, images, onCompletion) = action {
                onCompletion(.success(.fake().copy(images: images)))
            }
        }

        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(siteID: siteID, productID: productID, isLocalID: false, originalImages: []))

        // When
        // Uploads an image and waits for the image upload completion closure to be called later.
        let imageUploadCompletion: ((Result<Media, Error>) -> Void) = waitFor { promise in
            stores.whenReceivingAction(ofType: MediaAction.self) { action in
                if case let .uploadMedia(_, _, _, onCompletion) = action {
                    promise(onCompletion)
                }
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        }

        XCTAssertTrue(imageUploader.hasUnsavedChangesOnImages(siteID: siteID, productID: productID, isLocalID: false, originalImages: []))

        // The first save.
        imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(siteID: self.siteID, productID: self.productID, isLocalID: false) { result in
            XCTFail("The product save callback should not be triggered after another save request.")
        }

        // Adds a remote image.
        actionHandler.addSiteMediaLibraryImagesToProduct(mediaItems: [.fake().copy(mediaID: 606)])
        waitFor { promise in
            actionHandler.addUpdateObserver(self) { statuses in
                promise(())
            }
        }

        let resultOfSavedImages: Result<[ProductImage], Error> = waitFor { promise in
            // The second save.
            imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(siteID: self.siteID, productID: self.productID, isLocalID: false) { result in
                promise(result)
            }
            // Triggers success from image upload.
            imageUploadCompletion(.success(.fake().copy(mediaID: 645)))
        }

        // Then
        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(siteID: siteID,
                                                               productID: productID,
                                                               isLocalID: false,
                                                               originalImages: [.fake().copy(imageID: 606), .fake().copy(imageID: 645)]))
        XCTAssertTrue(resultOfSavedImages.isSuccess)
        let images = try XCTUnwrap(resultOfSavedImages.get())
        XCTAssertEqual(images.map { $0.imageID }, [606, 645])
    }

    func test_replaceLocalID_replaces_productID_properly() {
        // Given
        let imageUploader = ProductImageUploader()
        let localProductID: Int64 = 0
        let remoteProductID = productID
        let originalStatuses: [ProductImageStatus] = [.remote(image: ProductImage.fake()),
                                                      .uploading(asset: PHAsset()),
                                                      .uploading(asset: PHAsset())]
        _ = imageUploader.actionHandler(siteID: siteID,
                                        productID: localProductID,
                                        isLocalID: true,
                                        originalStatuses: originalStatuses)

        // Before replacing product ID

        // Pass empty statuses to get the `actionHandler`, and validate that `actionHandler` with `originalStatuses` is returned.
        XCTAssertEqual(originalStatuses, imageUploader.actionHandler(siteID: siteID,
                                                                     productID: localProductID,
                                                                     isLocalID: true,
                                                                     originalStatuses: []).productImageStatuses)

        // When
        imageUploader.replaceLocalID(siteID: siteID, localProductID: localProductID, remoteProductID: remoteProductID)

        // After replacing local product ID with remote product ID

        // Pass empty statuses and `remoteProductID` to get the `actionHandler`, and validate that `actionHandler` with `originalStatuses` is returned.
        XCTAssertEqual(originalStatuses, imageUploader.actionHandler(siteID: siteID,
                                                                     productID: remoteProductID,
                                                                     isLocalID: false,
                                                                     originalStatuses: []).productImageStatuses)
    }

    func test_calling_replaceLocalID_with_nonExistent_localProductID_does_nothing() {
        // Given
        let imageUploader = ProductImageUploader()
        let localProductID: Int64 = 0
        let nonExistentProductID: Int64 = 999
        let remoteProductID = productID
        let originalStatuses: [ProductImageStatus] = [.remote(image: ProductImage.fake()),
                                                      .uploading(asset: PHAsset()),
                                                      .uploading(asset: PHAsset())]
        _ = imageUploader.actionHandler(siteID: siteID,
                                        productID: localProductID,
                                        isLocalID: true,
                                        originalStatuses: originalStatuses)

        // When
        imageUploader.replaceLocalID(siteID: siteID, localProductID: nonExistentProductID, remoteProductID: remoteProductID)

        // Then
        // Ensure that trying to replace a non-existent product ID does nothing.
        XCTAssertEqual(originalStatuses, imageUploader.actionHandler(siteID: siteID,
                                                                     productID: localProductID,
                                                                     isLocalID: true,
                                                                     originalStatuses: []).productImageStatuses)
    }
    
    func test_replaceLocalID_fires_updateImageProductID_in_ProductImagesProductIDUpdater() {
        // Given
        let mockProductIDUpdater = MockProductImagesProductIDUpdater()
        let imageUploader = ProductImageUploader(imagesProductIDUpdater: mockProductIDUpdater)
        let localProductID: Int64 = 0
        let remoteProductID = productID
        let alreadyUploadedImages = [ProductImage.fake(),
                                     ProductImage.fake()]
        let originalStatuses: [ProductImageStatus] = alreadyUploadedImages.map({ .remote(image: $0) }) + [.uploading(asset: PHAsset())]
        
        _ = imageUploader.actionHandler(siteID: siteID,
                                        productID: localProductID,
                                        isLocalID: true,
                                        originalStatuses: originalStatuses)
        
        // When
        imageUploader.replaceLocalID(siteID: siteID, localProductID: localProductID, remoteProductID: remoteProductID)
        
        /// Then
        /// After replacing local product ID with remote product ID
        /// `mockProductIDUpdater` should have received calls to update product ID of the already uploaded images.
        waitUntil(condition: {
            mockProductIDUpdater.numberOfTimesUpdateImageProductIDWasCalled == alreadyUploadedImages.count
        })
    }
}

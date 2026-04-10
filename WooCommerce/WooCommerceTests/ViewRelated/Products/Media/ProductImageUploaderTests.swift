@testable import WooCommerce
import Combine
import Photos
import XCTest
import Yosemite
import Networking

final class ProductImageUploaderTests: XCTestCase {
    private let siteID: Int64 = 134
    private let productID = ProductOrVariationID.product(id: 606)
    private var errorsSubscription: AnyCancellable?
    private var assetUploadSubscription: AnyCancellable?
    private var activeUploadsSubscription: AnyCancellable?
    private var mockFeatureFlagService: MockFeatureFlagService!
    private var storage: ProductImageStatusStorage!
    private var testDefaults: UserDefaults!
    private var testUserDefaultsName: String!

    override func setUp() {
        super.setUp()
        mockFeatureFlagService = MockFeatureFlagService()

        // Create a truly unique UserDefaults instance for each test run
        testUserDefaultsName = "test.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testUserDefaultsName)!
        storage = ProductImageStatusStorage(userDefaults: testDefaults, key: testUserDefaultsName)
    }

    override func tearDown() {
        // Cancel all subscriptions
        errorsSubscription?.cancel()
        errorsSubscription = nil

        assetUploadSubscription?.cancel()
        assetUploadSubscription = nil

        activeUploadsSubscription?.cancel()
        activeUploadsSubscription = nil

        // Clean up storage
        storage.clearAllStatuses()
        storage = nil

        mockFeatureFlagService = nil

        // Remove the UserDefaults suite
        testDefaults.removeSuite(named: testUserDefaultsName)
        testDefaults = nil
        testUserDefaultsName = nil

        super.tearDown()
    }

    private func createImageUploader(stores: StoresManager,
                                     featureFlag: MockFeatureFlagService,
                                     productIDUpdater: ProductImagesProductIDUpdaterProtocol = MockProductImagesProductIDUpdater()) -> ProductImageUploader {
        return ProductImageUploader(
            stores: stores,
            featureFlagService: featureFlag,
            imagesProductIDUpdater: productIDUpdater,
            imageStatusStorage: storage
        )
    }

    // MARK: - Tests with Feature Flag Disabled

    func test_hasUnsavedChangesOnImages_becomes_false_after_uploading_and_saving() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let mockProductIDUpdater = MockProductImagesProductIDUpdater()
        let imageUploader = createImageUploader(stores: stores,
                                                featureFlag: mockFeatureFlagService,
                                                productIDUpdater: mockProductIDUpdater)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: false),
                                                        originalStatuses: [])
        let asset = PHAsset()

        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(key: .init(siteID: siteID,
                                                                          productOrVariationID: .product(id: productID.id),
                                                                          isLocalID: false),
                                                               originalImages: []))

        // When
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: asset))
        let statuses = waitFor { promise in
            actionHandler.addUpdateObserver(self) { statuses in
                promise(statuses)
            }
        }
        XCTAssertTrue(statuses.hasPendingUpload)
        XCTAssertTrue(imageUploader.hasUnsavedChangesOnImages(key: .init(siteID: siteID,
                                                                         productOrVariationID: .product(id: productID.id),
                                                                         isLocalID: false),
                                                              originalImages: []))
        imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(key: .init(siteID: siteID,
                                                                                 productOrVariationID: .product(id: productID.id),
                                                                                 isLocalID: false)) { _ in }

        // Then
        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(key: .init(siteID: siteID,
                                                                          productOrVariationID: .product(id: productID.id),
                                                                          isLocalID: false),
                                                               originalImages: []))
    }

    func test_hasUnsavedChangesOnImages_stays_false_after_uploading_and_saving_successfully() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: false),
                                                        originalStatuses: [])
        let asset = PHAsset()

        let uploadedMedia = Media.fake().copy(mediaID: 645)
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.success(uploadedMedia))
            }
        }
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, images, onCompletion) = action {
                onCompletion(.success(.fake().copy(siteID: self.siteID, productID: self.productID.id, images: images)))
            }
        }

        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(key: .init(siteID: siteID,
                                                                          productOrVariationID: productID,
                                                                          isLocalID: false),
                                                               originalImages: []))

        // When
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: asset))
        let statuses = waitFor { promise in
            actionHandler.addUpdateObserver(self) { statuses in
                if statuses.hasPendingUpload {
                    promise(statuses)
                }
            }
        }
        XCTAssertTrue(statuses.hasPendingUpload)
        XCTAssertTrue(imageUploader.hasUnsavedChangesOnImages(key: .init(siteID: siteID,
                                                                         productOrVariationID: productID,
                                                                         isLocalID: false),
                                                              originalImages: []))
        let resultOfSavedImages = waitFor { promise in
            imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(key: .init(siteID: self.siteID,
                                                                                     productOrVariationID: self.productID,
                                                                                     isLocalID: false)) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(key: .init(siteID: siteID,
                                                                          productOrVariationID: productID,
                                                                          isLocalID: false),
                                                               originalImages: [.fake().copy(imageID: 645)]))
        XCTAssertTrue(resultOfSavedImages.isSuccess)
        let images = try XCTUnwrap(resultOfSavedImages.get())
        XCTAssertEqual(images.map { $0.imageID }, [uploadedMedia.mediaID])
    }

    func test_when_saving_product_twice_the_latest_images_are_saved() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: false),
                                                        originalStatuses: [])
        let asset = PHAsset()

        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, images, onCompletion) = action {
                onCompletion(.success(.fake().copy(images: images)))
            }
        }

        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(key: .init(siteID: siteID,
                                                                          productOrVariationID: productID,
                                                                          isLocalID: false),
                                                               originalImages: []))

        // When
        // Uploads an image and waits for the image upload completion closure to be called later.
        let imageUploadCompletion: ((Result<Media, Error>) -> Void) = waitFor { promise in
            stores.whenReceivingAction(ofType: MediaAction.self) { action in
                if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                    promise(onCompletion)
                }
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: asset))
        }

        XCTAssertTrue(imageUploader.hasUnsavedChangesOnImages(key: .init(siteID: siteID,
                                                                         productOrVariationID: productID,
                                                                         isLocalID: false), originalImages: []))

        // The first save.
        imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(key:
                .init(siteID: self.siteID,
                      productOrVariationID: self.productID,
                      isLocalID: false)) { result in
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
            imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(key:
                    .init(siteID: self.siteID,
                          productOrVariationID: self.productID,
                          isLocalID: false)) { result in
                promise(result)
            }
            // Triggers success from image upload.
            imageUploadCompletion(.success(.fake().copy(mediaID: 645)))
        }

        // Then
        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(key: .init(siteID: siteID,
                                                                          productOrVariationID: productID,
                                                                          isLocalID: false),
                                                               originalImages: [.fake().copy(imageID: 606), .fake().copy(imageID: 645)]))
        XCTAssertTrue(resultOfSavedImages.isSuccess)
        let images = try XCTUnwrap(resultOfSavedImages.get())
        XCTAssertEqual(images.map { $0.imageID }, [606, 645])
    }

    func test_replaceLocalID_replaces_productID_properly() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let mockProductIDUpdater = MockProductImagesProductIDUpdater()
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService, productIDUpdater: mockProductIDUpdater)
        let localProductID: Int64 = 0
        let remoteProductID = productID.id
        let originalStatuses: [ProductImageStatus] = [.remote(image: ProductImage.fake(), siteID: siteID, productID: productID),
                                                      .uploading(asset: .phAsset(asset: PHAsset()), siteID: siteID, productID: productID),
                                                      .uploading(asset: .phAsset(asset: PHAsset()), siteID: siteID, productID: productID)]
        _ = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                   productOrVariationID: .product(id: localProductID),
                                                   isLocalID: true),
                                        originalStatuses: originalStatuses)

        // Before replacing product ID

        // Pass empty statuses to get the `actionHandler`, and validate that `actionHandler` with `originalStatuses` is returned.
        XCTAssertEqual(originalStatuses, imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                                productOrVariationID: .product(id: localProductID),
                                                                                isLocalID: true),
                                                                     originalStatuses: []).productImageStatuses)

        // When
        imageUploader.replaceLocalID(siteID: siteID, localID: .product(id: localProductID), remoteID: remoteProductID)

        // After replacing local product ID with remote product ID

        // Pass empty statuses and `remoteProductID` to get the `actionHandler`, and validate that `actionHandler` with `originalStatuses` is returned.
        XCTAssertEqual(originalStatuses, imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                                productOrVariationID: .product(id: remoteProductID),
                                                                                isLocalID: false),
                                                                     originalStatuses: []).productImageStatuses)
    }

    func test_calling_replaceLocalID_with_nonExistent_localProductID_does_nothing() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let mockProductIDUpdater = MockProductImagesProductIDUpdater()
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService, productIDUpdater: mockProductIDUpdater)
        let localProductID: Int64 = 0
        let nonExistentProductID: Int64 = 999
        let remoteProductID = productID.id
        let originalStatuses: [ProductImageStatus] = [.remote(image: ProductImage.fake(), siteID: siteID, productID: productID),
                                                      .uploading(asset: .phAsset(asset: PHAsset()), siteID: siteID, productID: productID),
                                                      .uploading(asset: .phAsset(asset: PHAsset()), siteID: siteID, productID: productID)]
        _ = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                   productOrVariationID: .product(id: localProductID),
                                                   isLocalID: true),
                                        originalStatuses: originalStatuses)

        // When
        imageUploader.replaceLocalID(siteID: siteID, localID: .product(id: nonExistentProductID), remoteID: remoteProductID)

        // Then
        // Ensure that trying to replace a non-existent product ID does nothing.
        XCTAssertEqual(originalStatuses, imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                                productOrVariationID: .product(id: localProductID),
                                                                                isLocalID: true),
                                                                     originalStatuses: []).productImageStatuses)
    }

    func test_product_id_of_uploaded_image_is_updated_after_saving_product() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let mockProductIDUpdater = MockProductImagesProductIDUpdater()
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService, productIDUpdater: mockProductIDUpdater)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: false),
                                                        originalStatuses: [])

        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.success(.fake()))
            }
        }
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, _, onCompletion) = action {
                onCompletion(.success(.fake()))
            }
        }

        // When
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: PHAsset()))
        waitForExpectation { expectation in
            self.assetUploadSubscription = actionHandler.addUpdateObserver(self) { statuses in
                if statuses.hasPendingUpload == false {
                    expectation.fulfill()
                }
            }
        }

        imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(key: .init(siteID: siteID,
                                                                                 productOrVariationID: productID,
                                                                                 isLocalID: false)) { result in }

        // Then
        waitUntil {
            mockProductIDUpdater.updateImageProductIDWasCalled
        }
    }

    // MARK: - Error updates

    func test_actionHandler_error_is_emitted_when_image_upload_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: true),
                                                        originalStatuses: [])
        let error = NSError(domain: "", code: 6)
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.failure(error))
            }
        }

        // When
        var errors: [ProductImageUploadErrorInfo] = []
        let asset = ProductImageAssetType.phAsset(asset: PHAsset())
        let _: Void = waitFor { promise in
            self.errorsSubscription = imageUploader.errors.sink { error in
                errors.append(error)
                promise(())
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        }

        // Then
        assertEqual([.init(siteID: siteID,
                           productOrVariationID: productID,
                           error: ProductImageUploaderError.failedUploadingImage(asset: asset, error: error))],
                    errors)
    }

    func test_savingProductImages_error_is_emitted_when_saving_images_fails() throws {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: false),
                                                        originalStatuses: [])

        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.success(.fake()))
            }
        }
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, _, onCompletion) = action {
                onCompletion(.failure(.unexpected))
            }
        }

        // When
        let asset = PHAsset()
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: asset))
        waitFor { promise in
            actionHandler.addUpdateObserver(self) { statuses in
                promise(())
            }
        }
        imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(key: .init(siteID: siteID,
                                                                                 productOrVariationID: productID,
                                                                                 isLocalID: false)) { result in }
        var errors: [ProductImageUploadErrorInfo] = []
        let _: Void = waitFor { promise in
            self.errorsSubscription = imageUploader.errors.sink { error in
                errors.append(error)
                promise(())
            }
        }

        // Then
        assertEqual([.init(siteID: siteID,
                           productOrVariationID: productID,
                           error: .failedSavingProductAfterImageUpload(error: ProductUpdateError.unexpected))],
                    errors)
    }

    func test_errors_are_not_emitted_when_image_upload_succeeds() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: true),
                                                        originalStatuses: [])
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.success(.fake()))
            }
        }

        // When
        var errors: [ProductImageUploadErrorInfo] = []
        errorsSubscription = imageUploader.errors.sink { error in
            errors.append(error)
            XCTFail("Image upload update should be emitted: \(error)")
        }
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: PHAsset()))

        // Then
        XCTAssertTrue(errors.isEmpty)
    }

    // MARK: - `stopEmittingErrors`

    func test_error_is_emitted_after_stopEmittingErrors_with_a_different_product_when_image_upload_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: true),
                                                        originalStatuses: [])
        let error = NSError(domain: "", code: 6)
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.failure(error))
            }
        }

        // When
        imageUploader.stopEmittingErrors(key: .init(siteID: siteID,
                                                    productOrVariationID: .product(id: 9999),
                                                    isLocalID: true))

        let asset = ProductImageAssetType.phAsset(asset: PHAsset())
        var errors: [ProductImageUploadErrorInfo] = []
        let _: Void = waitFor { promise in
            self.errorsSubscription = imageUploader.errors.sink { error in
                errors.append(error)
                promise(())
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        }

        // Then
        assertEqual([.init(siteID: siteID,
                           productOrVariationID: productID,
                           error: .failedUploadingImage(asset: asset, error: error))],
                    errors)
    }

    func test_error_is_not_emitted_after_stopEmittingErrors_when_image_upload_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: true),
                                                        originalStatuses: [])
        let error = NSError(domain: "", code: 6)
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.failure(error))
            }
        }

        // When
        imageUploader.stopEmittingErrors(key: .init(siteID: siteID,
                                                    productOrVariationID: productID,
                                                    isLocalID: true))

        var errors: [ProductImageUploadErrorInfo] = []
        errorsSubscription = imageUploader.errors.sink { error in
            errors.append(error)
            XCTFail("Image upload update should be emitted: \(error)")
        }
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: PHAsset()))

        // Then
        XCTAssertTrue(errors.isEmpty)
    }

    func test_calling_replaceLocalID_updates_excluded_product_from_status_updates() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let localProductID: Int64 = 0
        let nonExistentProductID: Int64 = 999
        let remoteProductID = productID
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: .product(id: localProductID),
                                                                   isLocalID: true),
                                                        originalStatuses: [])

        // When
        imageUploader.stopEmittingErrors(key: .init(siteID: siteID,
                                                    productOrVariationID: .product(id: localProductID),
                                                    isLocalID: true))
        imageUploader.replaceLocalID(siteID: siteID,
                                     localID: .product(id: nonExistentProductID),
                                     remoteID: remoteProductID.id)

        var errors: [ProductImageUploadErrorInfo] = []
        _ = imageUploader.errors.sink { error in
            errors.append(error)
        }

        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.failure(MediaActionError.unknown))
            }
        }
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: PHAsset()))

        // Then
        XCTAssertTrue(errors.isEmpty)
    }

    // MARK: - `startEmittingErrors`

    func test_error_is_emitted_after_stop_and_startEmittingErrors_when_image_upload_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: true),
                                                        originalStatuses: [])
        let error = NSError(domain: "", code: 6)
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.failure(error))
            }
        }

        // When
        imageUploader.stopEmittingErrors(key: .init(siteID: siteID,
                                                    productOrVariationID: productID,
                                                    isLocalID: true))
        imageUploader.startEmittingErrors(key: .init(siteID: siteID,
                                                     productOrVariationID: productID,
                                                     isLocalID: true))

        var errors: [ProductImageUploadErrorInfo] = []
        let asset = ProductImageAssetType.phAsset(asset: PHAsset())
        let _: Void = waitFor { promise in
            self.errorsSubscription = imageUploader.errors.sink { error in
                errors.append(error)
                promise(())
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: asset)
        }

        // Then
        assertEqual([.init(siteID: siteID,
                           productOrVariationID: productID,
                           error: ProductImageUploaderError.failedUploadingImage(asset: asset, error: error))],
                    errors)
    }

    // MARK: - `reset`

    func test_image_upload_error_is_not_emitted_after_reset() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let actionHandler = imageUploader.actionHandler(key: .init(siteID: siteID,
                                                                   productOrVariationID: productID,
                                                                   isLocalID: true),
                                                        originalStatuses: [])
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.failure(NSError(domain: "", code: 6)))
            }
        }

        var errors: [ProductImageUploadErrorInfo] = []
        errorsSubscription = imageUploader.errors.sink { error in
            errors.append(error)
            XCTFail("Image upload error should not be emitted: \(error)")
        }

        // When
        imageUploader.reset()

        let _: Void = waitFor { promise in
            self.assetUploadSubscription = actionHandler.addUpdateObserver(self) { statuses in
                if statuses.contains(where: { status in
                    switch status {
                    case .uploadFailure: true
                    case .remote, .uploading: false
                    }
                }) {
                    promise(())
                }
            }
            actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: PHAsset()))
        }

        // Then
        XCTAssertEqual(errors.count, 0)
    }

    // MARK: `activeUploads`

    func test_product_is_removed_from_activeUploads_when_upload_completes() {
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let key = ProductImageUploaderKey(siteID: siteID,
                                          productOrVariationID: productID,
                                          isLocalID: false)
        let actionHandler = imageUploader.actionHandler(key: key, originalStatuses: [])

        var activeUploads: [ProductImageUploaderKey] = []
        activeUploadsSubscription = imageUploader.activeUploads
            .sink { keys in
                activeUploads = keys
            }

        // When
        let asset = PHAsset()
        let uploadedMedia = Media.fake().copy(mediaID: 645)
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                XCTAssertEqual(activeUploads, [key])
                onCompletion(.success(uploadedMedia))

                // Then
                self.waitUntil {
                    activeUploads == []
                }
            }
        }
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: asset))
    }

    func test_product_is_removed_from_activeUploads_when_upload_is_cancelled() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let key = ProductImageUploaderKey(siteID: siteID,
                                          productOrVariationID: productID,
                                          isLocalID: false)
        let actionHandler = imageUploader.actionHandler(key: key, originalStatuses: [])
        let productFormDataModel = EditableProductModel(product: .fake().copy(siteID: siteID, productID: productID.id, images: []))

        var activeUploads: [ProductImageUploaderKey] = []
        activeUploadsSubscription = imageUploader.activeUploads
            .sink { keys in
                activeUploads = keys
            }

        // When
        let asset = PHAsset()
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: asset))

        // Then
        waitUntil {
            activeUploads == [key]
        }

        // When
        actionHandler.resetProductImages(to: productFormDataModel)

        // Then
        waitUntil {
            activeUploads == []
        }
    }

    func test_background_upload_notice_is_sent_when_there_are_active_uploads() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)
        let key = ProductImageUploaderKey(siteID: siteID,
                                          productOrVariationID: productID,
                                          isLocalID: false)
        let actionHandler = imageUploader.actionHandler(key: key, originalStatuses: [])

        let noticePresenter = MockNoticePresenter()
        var isNoticeTriggered = false
        noticePresenter.onNoticeQueued = { _ in
            isNoticeTriggered = true
        }

        var activeUploads: [ProductImageUploaderKey] = []
        activeUploadsSubscription = imageUploader.activeUploads
            .sink { keys in
                activeUploads = keys
            }

        // When
        imageUploader.sendBackgroundUploadNoticeIfNeeded(key: key, using: noticePresenter)

        // Then
        XCTAssertFalse(isNoticeTriggered)

        // When
        let asset = PHAsset()
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: asset))
        waitUntil {
            activeUploads == [key]
        }

        // Then
        imageUploader.sendBackgroundUploadNoticeIfNeeded(key: key, using: noticePresenter)
        XCTAssertTrue(isNoticeTriggered)
    }

    // MARK: - Tests with background image upload feature flag enabled

    func test_hasUnsavedChangesOnImages_becomes_false_after_uploading_and_saving_with_flag_enabled() throws {
        // Given
        mockFeatureFlagService = MockFeatureFlagService(backgroundProductImageUpload: true)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let mockProductIDUpdater = MockProductImagesProductIDUpdater()
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService, productIDUpdater: mockProductIDUpdater)
        let key = ProductImageUploaderKey(siteID: siteID,
                                        productOrVariationID: productID,
                                        isLocalID: false)
        let actionHandler = imageUploader.actionHandler(key: key, originalStatuses: [])
        let asset = PHAsset()

        // Initial state - no unsaved changes
        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(key: key, originalImages: []),
                     "Should not have unsaved changes initially")

        // When - Upload an image
        let uploadedMedia = Media.fake().copy(mediaID: 645)
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                onCompletion(.success(uploadedMedia))
            }
        }

        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: asset))

        // Wait for the upload to be processed
        let _ = waitFor { promise in
            actionHandler.addUpdateObserver(self) { statuses in
                if !statuses.isEmpty {
                    promise(statuses)
                }
            }
        }

        // Verify upload created unsaved changes
        XCTAssertTrue(imageUploader.hasUnsavedChangesOnImages(key: key, originalImages: []),
                    "Should have unsaved changes after uploading an image")

        // When - Save the product with new images
        stores.whenReceivingAction(ofType: ProductAction.self) { action in
            if case let .updateProductImages(_, _, images, onCompletion) = action {
                onCompletion(.success(.fake().copy(siteID: self.siteID, productID: self.productID.id, images: images)))
            }
        }

        let saveResult: Result<[ProductImage], Error> = waitFor { promise in
            imageUploader.saveProductImagesWhenNoneIsPendingUploadAnymore(key: key) { result in
                promise(result)
            }
        }

        // Then - Verify save succeeded and changes are no longer unsaved
        XCTAssertTrue(saveResult.isSuccess, "Product save should succeed")
        if case .success(let images) = saveResult {
            XCTAssertEqual(images.count, 1, "Should have saved one image")
            XCTAssertEqual(images.first?.imageID, uploadedMedia.mediaID, "Saved image should match uploaded media")
        }

        XCTAssertFalse(imageUploader.hasUnsavedChangesOnImages(key: key, originalImages: [.fake().copy(imageID: 645)]),
                      "Should not have unsaved changes after saving")
    }

    func test_error_is_published_through_storage_with_flag_enabled() {
        // Given
        mockFeatureFlagService = MockFeatureFlagService(backgroundProductImageUpload: true)

        let asset = ProductImageAssetType.phAsset(asset: PHAsset())
        let error = NSError(domain: "test", code: 123)
        let expectedError = ProductImageUploadErrorInfo(
            siteID: siteID,
            productOrVariationID: productID,
            error: .failedUploadingImage(asset: asset, error: error)
        )

        let errorsSubject = PassthroughSubject<ProductImageUploadErrorInfo, Never>()
        let mockImageUploader = MockProductImageUploader(errors: errorsSubject.eraseToAnyPublisher())

        var receivedErrors: [ProductImageUploadErrorInfo] = []
        errorsSubscription = mockImageUploader.errors.sink { error in
            receivedErrors.append(error)
        }

        // When - simulate an error in the storage
        errorsSubject.send(expectedError)

        // Then
        XCTAssertEqual(receivedErrors.count, 1)
        XCTAssertEqual(receivedErrors.first?.siteID, siteID)
        XCTAssertEqual(receivedErrors.first?.productOrVariationID, productID)
        if case let .failedUploadingImage(receivedAsset, receivedError) = receivedErrors.first?.error {
            XCTAssertEqual(receivedAsset, asset)
            XCTAssertEqual((receivedError as NSError).domain, error.domain)
            XCTAssertEqual((receivedError as NSError).code, error.code)
        } else {
            XCTFail("Expected failedUploadingImage error")
        }
    }

    func test_activeUploads_are_tracked_through_storage_with_flag_enabled() {
        // Given
        mockFeatureFlagService = MockFeatureFlagService(backgroundProductImageUpload: true)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)

        let key = ProductImageUploaderKey(siteID: siteID,
                                         productOrVariationID: productID,
                                         isLocalID: false)

        // Ensure storage is empty at the start
        XCTAssertEqual(storage.getAllStatuses().count, 0, "Storage should be empty at test start")

        // Set up subscription to track active uploads
        var activeUploads: [ProductImageUploaderKey] = []
        activeUploadsSubscription = imageUploader.activeUploads.sink { keys in
            activeUploads = keys
        }

        // Initially there should be no active uploads
        XCTAssertTrue(activeUploads.isEmpty)

        // When - Upload an image to create an active upload
        let actionHandler = imageUploader.actionHandler(key: key, originalStatuses: [])

        // Configure the stores manager to not complete the upload immediately
        var uploadCompletion: ((Result<Media, Error>) -> Void)?
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case let .uploadMedia(_, _, _, _, _, onCompletion) = action {
                uploadCompletion = onCompletion
                // Don't call completion yet to keep the upload "in progress"
            }
        }

        // Start the upload
        let mockAsset = PHAsset()
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .phAsset(asset: mockAsset))

        // Wait for the upload to be reflected in the active uploads
        let uploadDetectedExpectation = expectation(description: "Upload detected in active uploads")
        var uploadCheckCancellable: AnyCancellable?
        uploadCheckCancellable = imageUploader.activeUploads
            .sink { currentUploads in
                if currentUploads.contains(key) {
                    uploadDetectedExpectation.fulfill()
                    uploadCheckCancellable?.cancel()
                }
            }
        wait(for: [uploadDetectedExpectation], timeout: 3.0)

        // Verify the upload is being tracked
        XCTAssertEqual(activeUploads.count, 1)
        XCTAssertEqual(activeUploads.first?.siteID, key.siteID)
        XCTAssertEqual(activeUploads.first?.productOrVariationID, key.productOrVariationID)

        // When - Complete the upload
        uploadCompletion?(.success(.fake().copy(mediaID: 999)))

        // Then - Wait for the active upload to be removed
        let uploadCompletedExpectation = expectation(description: "Upload removed from active uploads")
        var completionCheckCancellable: AnyCancellable?
        completionCheckCancellable = imageUploader.activeUploads
            .sink { currentUploads in
                if currentUploads.isEmpty {
                    uploadCompletedExpectation.fulfill()
                    completionCheckCancellable?.cancel()
                }
            }
        wait(for: [uploadCompletedExpectation], timeout: 3.0)

        // Verify all uploads are finished
        XCTAssertTrue(activeUploads.isEmpty)
    }

    func test_background_upload_notice_is_sent_when_there_are_active_uploads_with_flag_enabled() {
        // Given
        mockFeatureFlagService = MockFeatureFlagService(backgroundProductImageUpload: true)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores,
                                                 featureFlag: mockFeatureFlagService)

        let key = ProductImageUploaderKey(siteID: siteID,
                                          productOrVariationID: productID,
                                          isLocalID: false)

        let noticePresenter = MockNoticePresenter()
        var isNoticeTriggered = false
        noticePresenter.onNoticeQueued = { _ in
            isNoticeTriggered = true
        }

        // Monitor active uploads
        var activeUploads: [ProductImageUploaderKey] = []
        activeUploadsSubscription = imageUploader.activeUploads.sink { keys in
            activeUploads = keys
        }

        // Verify that there are no uploads at the beginning
        XCTAssertEqual(storage.getAllStatuses().count, 0, "Storage should be empty at the beginning")

        // When - No active uploads
        imageUploader.sendBackgroundUploadNoticeIfNeeded(key: key, using: noticePresenter)

        // Then
        XCTAssertFalse(isNoticeTriggered, "No notice should be triggered when there are no active uploads")

        // Reset the notice flag
        isNoticeTriggered = false

        // Create an uploading status directly in storage
        let uploadingStatus = ProductImageStatus.uploading(
            asset: .uiImage(image: .checkmark, filename: "test", altText: "alt_test"),
            siteID: siteID,
            productID: productID
        )
        storage.addStatus(uploadingStatus)

        // Wait for the active upload to be registered
        waitUntil(timeout: 3) {
            activeUploads.contains(key)
        }

        // When - With active uploads
        imageUploader.sendBackgroundUploadNoticeIfNeeded(key: key, using: noticePresenter)

        // Then
        XCTAssertTrue(isNoticeTriggered, "Notice should be triggered when there are active uploads")
    }

    func test_reset_clears_storage_state_with_flag_enabled() {
        // Given
        mockFeatureFlagService = MockFeatureFlagService(backgroundProductImageUpload: true)
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let imageUploader = createImageUploader(stores: stores, featureFlag: mockFeatureFlagService)

        let key = ProductImageUploaderKey(siteID: siteID,
                                        productOrVariationID: productID,
                                        isLocalID: false)

        // Configure the store to keep uploads in progress. Don't call completion to keep it in uploading state.
        stores.whenReceivingAction(ofType: MediaAction.self) { action in
            if case .uploadMedia = action {
            }
        }

        // Add a status to storage by uploading an image
        let actionHandler = imageUploader.actionHandler(key: key, originalStatuses: [])
        actionHandler.uploadMediaAssetToSiteMediaLibrary(asset: .uiImage(image: .checkmark, filename: "test", altText: "alt_test"))

        // Wait for the upload to be registered
        let uploadStatus = waitFor { promise in
            actionHandler.addUpdateObserver(self) { statuses in
                if statuses.hasPendingUpload {
                    promise(statuses)
                }
            }
        }

        // Verify we have a pending upload
        XCTAssertTrue(uploadStatus.hasPendingUpload)

        // Set up subscription to track active uploads
        var activeUploads: [ProductImageUploaderKey] = []
        activeUploadsSubscription = imageUploader.activeUploads.sink { keys in
            activeUploads = keys
        }

        // Wait for the active upload to be registered
        waitUntil() {
            activeUploads.contains { $0 == key }
        }

        // When
        imageUploader.reset()

        // Then - Active uploads should be cleared
        waitUntil() {
            activeUploads.isEmpty
        }
    }
}

extension ProductImageUploadErrorInfo: @retroactive Equatable {
    public static func == (lhs: ProductImageUploadErrorInfo, rhs: ProductImageUploadErrorInfo) -> Bool {
        return lhs.siteID == rhs.siteID &&
        lhs.productOrVariationID == rhs.productOrVariationID &&
        lhs.error == rhs.error
    }
}

extension ProductImageUploaderError: @retroactive Equatable {
    public static func == (lhs: ProductImageUploaderError, rhs: ProductImageUploaderError) -> Bool {
        switch (lhs, rhs) {
        case let (.failedUploadingImage(lAsset, lhsError), .failedUploadingImage(rAsset, rhsError)):
            return lhsError as NSError == rhsError as NSError && lAsset == rAsset
        case (.failedSavingProductAfterImageUpload(let lhsError), .failedSavingProductAfterImageUpload(let rhsError)):
            return lhsError as NSError == rhsError as NSError
        default:
            return false
        }
    }
}

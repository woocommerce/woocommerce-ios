import Combine
import UIKit
import Foundation
import struct Yosemite.ProductImage
import enum Yosemite.ProductAction
import protocol Yosemite.StoresManager
import enum Yosemite.ProductImageStatus
import enum Yosemite.ProductImageAssetType
import enum Yosemite.ProductOrVariationID
import class Networking.ProductImageStatusStorage
import protocol Experiments.FeatureFlagService

/// Information about a background product image upload error.
struct ProductImageUploadErrorInfo {
    let siteID: Int64
    let productOrVariationID: ProductOrVariationID
    let error: ProductImageUploaderError
}

/// Identifiable information about a specific product or product variation of different sites for image upload.
struct ProductImageUploaderKey: Equatable, Hashable {
    let siteID: Int64
    let productOrVariationID: ProductOrVariationID
    let isLocalID: Bool
}

/// Handles product image upload to support background image upload.
protocol ProductImageUploaderProtocol {

    /// Emits active image uploads
    var activeUploads: AnyPublisher<[ProductImageUploaderKey], Never> { get }

    /// Emits product image upload errors.
    var errors: AnyPublisher<ProductImageUploadErrorInfo, Never> { get }

    /// Called for product image upload use cases (e.g. product/variation form, downloadable product list).
    /// - Parameters:
    ///   - key: identifiable information about the product.
    ///   - originalStatuses: the current image statuses of the product for initialization.
    func actionHandler(key: ProductImageUploaderKey, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler

    /// Replaces the local ID of the product with the remote ID from API.
    ///
    /// Called in "Add product" flow as soon as the product is saved in the API.
    ///
    /// Replacing product ID is necessary to update the product with the images that are already uploaded without product ID.
    /// Note that the images start uploading even before the product is created in API.
    ///
    /// - Parameters:
    ///   - siteID: The ID of the site to which images are uploaded to.
    ///   - localID: A temporary local ID of the product.
    ///   - remoteID: Remote product ID received from API.
    func replaceLocalID(siteID: Int64, localID: ProductOrVariationID, remoteID: Int64)

    /// Saves the product remotely with the images after none is pending upload.
    /// - Parameters:
    ///   - key: identifiable information about the product.
    ///   - onProductSave: called after the product is saved remotely with the uploaded images.
    func saveProductImagesWhenNoneIsPendingUploadAnymore(key: ProductImageUploaderKey,
                                                         onProductSave: @escaping (Result<[ProductImage], Error>) -> Void)

    /// Stops the emission of errors when the user is in the product form to edit a specific product.
    /// - Parameters:
    ///   - key: identifiable information about the product.
    func stopEmittingErrors(key: ProductImageUploaderKey)

    /// Starts the emission of errors when the user leaves the product form.
    /// - Parameters:
    ///   - key: identifiable information about the product.
    func startEmittingErrors(key: ProductImageUploaderKey)

    /// Triggers a notice about background image upload for a product if needed.
    /// - Parameter key: identifiable information about the product.
    ///
    func sendBackgroundUploadNoticeIfNeeded(key: ProductImageUploaderKey, using noticePresenter: NoticePresenter)

    /// Determines whether there are unsaved changes on a product's images.
    /// If the product had any save request before, it checks whether the image statuses to save match the latest image statuses.
    /// Otherwise, it checks whether there is any pending upload or the image statuses match the given original image statuses.
    /// - Parameters:
    ///   - key: identifiable information about the product.
    ///   - originalImages: the image statuses before any edits.
    func hasUnsavedChangesOnImages(key: ProductImageUploaderKey, originalImages: [ProductImage]) -> Bool

    /// Resets all internal states and tracking of image uploads for connected stores.
    /// Called when the user is logged out.
    func reset()
}

/// Supports background image upload and product images update after the user leaves the product form.
final class ProductImageUploader: ProductImageUploaderProtocol {

    let imageStatusStorage: ProductImageStatusStorage

    var errors: AnyPublisher<ProductImageUploadErrorInfo, Never> {
        if featureFlagService.isFeatureFlagEnabled(.backgroundProductImageUpload) {
            return imageStatusStorage.errorsPublisher
                .flatMap { errorItems in
                    errorItems.publisher
                        .compactMap { errorItem in
                            guard let productOrVariationID = errorItem.productOrVariationID,
                                  let assetType = errorItem.assetType else { return nil }

                            // Create key to check against excluded keys
                            let key = Key(siteID: errorItem.siteID,
                                          productOrVariationID: productOrVariationID,
                                          isLocalID: productOrVariationID.id == 0)

                            // Skip error if it's for a product being edited
                            guard !self.statusUpdatesExcludedProductKeys.contains(key) else {
                                return nil
                            }

                            return ProductImageUploadErrorInfo(
                                siteID: errorItem.siteID,
                                productOrVariationID: productOrVariationID,
                                error: .failedUploadingImage(asset: assetType, error: errorItem.error)
                            )
                        }
                }
                .eraseToAnyPublisher()
        } else {
            return errorsSubject
                .filter { info in
                    let key = Key(siteID: info.siteID,
                                  productOrVariationID: info.productOrVariationID,
                                  isLocalID: info.productOrVariationID.id == 0)
                    return !self.statusUpdatesExcludedProductKeys.contains(key)
                }
                .eraseToAnyPublisher()
        }
    }

    var activeUploads: AnyPublisher<[ProductImageUploaderKey], Never> {
        if featureFlagService.isFeatureFlagEnabled(.backgroundProductImageUpload) {
            return imageStatusStorage.statusesPublisher
                .map { statuses in
                    statuses.compactMap { status -> ProductImageUploaderKey? in
                        if status.isUploading {
                            return ProductImageUploaderKey(siteID: status.siteID,
                                                           productOrVariationID: status.productOrVariationID,
                                                           isLocalID: status.isLocalID)
                        }
                        return nil
                    }
                }
                .eraseToAnyPublisher()
        } else {
            return $activeUploadsPublisher.eraseToAnyPublisher()
        }
    }

    typealias Key = ProductImageUploaderKey

    private let errorsSubject: PassthroughSubject<ProductImageUploadErrorInfo, Never> = .init()
    private var statusUpdatesExcludedProductKeys: Set<Key> = []
    private var statusUpdatesSubscriptions: Set<AnyCancellable> = []
    private var imageUploadSubscriptions: Set<AnyCancellable> = []

    private var actionHandlersByProduct: [Key: ProductImageActionHandler] = [:]
    private var imagesSaverByProduct: [Key: ProductImagesSaver] = [:]

    @Published private var activeUploadsPublisher: [ProductImageUploaderKey] = []

    private let stores: StoresManager
    private let featureFlagService: FeatureFlagService
    private let imagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol

    private var cancellables = Set<AnyCancellable>()

    init(stores: StoresManager = ServiceLocator.stores,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService,
         imagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol = ProductImagesProductIDUpdater(),
         imageStatusStorage: ProductImageStatusStorage = ProductImageStatusStorage()) {
        self.stores = stores
        self.featureFlagService = featureFlagService
        self.imagesProductIDUpdater = imagesProductIDUpdater
        self.imageStatusStorage = imageStatusStorage

        // Observe when the app enters background.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidEnterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func actionHandler(key: ProductImageUploaderKey, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        let actionHandler: ProductImageActionHandler
        if let handler = actionHandlersByProduct[key] {
            actionHandler = handler
        } else {
            actionHandler = ProductImageActionHandler(siteID: key.siteID, productID: key.productOrVariationID, imageStatuses: originalStatuses, stores: stores)
            actionHandlersByProduct[key] = actionHandler
            observeStatusUpdates(key: key, actionHandler: actionHandler)
            observeImageUploads(key: key, actionHandler: actionHandler)
        }

        return actionHandler
    }

    func replaceLocalID(siteID: Int64, localID: ProductOrVariationID, remoteID: Int64) {
        let key = Key(siteID: siteID,
                      productOrVariationID: localID,
                      isLocalID: true)
        guard let handler = actionHandlersByProduct[key] else {
            return
        }

        // Update the product ID of handler to make sure that future product image uploads use the `remoteProductID` instead of `localProductID`
        let remoteProductOrVariationID = localID.replacingID(remoteID)
        handler.updateProductID(remoteProductOrVariationID)

        actionHandlersByProduct.removeValue(forKey: key)
        let keyWithRemoteProductID = Key(siteID: siteID,
                                         productOrVariationID: remoteProductOrVariationID,
                                         isLocalID: false)
        actionHandlersByProduct[keyWithRemoteProductID] = handler

        statusUpdatesExcludedProductKeys.remove(key)
        statusUpdatesExcludedProductKeys.insert(keyWithRemoteProductID)
    }

    func stopEmittingErrors(key: ProductImageUploaderKey) {
        statusUpdatesExcludedProductKeys.insert(key)
    }

    func startEmittingErrors(key: ProductImageUploaderKey) {
        statusUpdatesExcludedProductKeys.remove(key)
    }

    func sendBackgroundUploadNoticeIfNeeded(key: ProductImageUploaderKey, using noticePresenter: NoticePresenter) {
        if featureFlagService.isFeatureFlagEnabled(.backgroundProductImageUpload) {
            let statuses = imageStatusStorage.getAllStatuses(for: key.siteID, productID: key.productOrVariationID)
            if statuses.contains(where: { $0.isUploading }) {
                let notice = Notice(title: Localization.backgroundUploadNoticeTitle)
                noticePresenter.enqueue(notice: notice)
            }
        } else {
            if activeUploadsPublisher.contains(key) {
                let notice = Notice(title: Localization.backgroundUploadNoticeTitle)
                noticePresenter.enqueue(notice: notice)
            }
        }
    }

    func hasUnsavedChangesOnImages(key: ProductImageUploaderKey, originalImages: [ProductImage]) -> Bool {
        guard let handler = actionHandlersByProduct[key] else {
            return false
        }
        let productImagesSaver = imagesSaverByProduct[key]

        if let productImagesSaver, productImagesSaver.imageStatusesToSave.isNotEmpty {
            // If there are images scheduled to be saved, there are no unsaved changes if the image statuses to save match the latest image statuses.
            return handler.productImageStatuses.images != productImagesSaver.imageStatusesToSave.images
        } else {
            if handler.productImageStatuses.hasPendingUpload {
                return true
            }

            /// If there's a product saved in background, compare the images to determine unsaved changes.
            if let savedProduct = productImagesSaver?.savedProduct {
                return handler.productImageStatuses.images.map { $0.imageID } != savedProduct.images.map { $0.imageID }
            }

            // Otherwise, there are unsaved changes if there is any difference in the remote image IDs between the
            // original and latest product.
            return handler.productImageStatuses.images.map { $0.imageID } != originalImages.map { $0.imageID }
        }
    }

    func saveProductImagesWhenNoneIsPendingUploadAnymore(key: ProductImageUploaderKey,
                                                         onProductSave: @escaping (Result<[ProductImage], Error>) -> Void) {
        // The product has to exist remotely in order to save its images remotely.
        // In product creation, this save function should be called after a new product is saved remotely for the first time.
        guard key.isLocalID == false else {
            return onProductSave(.failure(ProductImageUploaderError.noRemoteProductIDFound))
        }

        guard let handler = actionHandlersByProduct[key] else {
            return onProductSave(.failure(ProductImageUploaderError.noActionHandlerFound))
        }

        let imagesSaver: ProductImagesSaver
        if let productImagesSaver = imagesSaverByProduct[key] {
            imagesSaver = productImagesSaver
        } else {
            imagesSaver = ProductImagesSaver(siteID: key.siteID,
                                             productOrVariationID: key.productOrVariationID,
                                             stores: stores)
            imagesSaverByProduct[key] = imagesSaver
        }

        imagesSaver.saveProductImagesWhenNoneIsPendingUploadAnymore(imageActionHandler: handler) { [weak self] result in
            guard let self = self else { return }
            onProductSave(result)
            if case let .failure(error) = result {
                self.errorsSubject.send(.init(siteID: key.siteID,
                                              productOrVariationID: key.productOrVariationID,
                                              error: .failedSavingProductAfterImageUpload(error: error)))
            }
            self.updateProductIDOfImagesUploadedUsingLocalProductID(siteID: key.siteID,
                                                                    productOrVariationID: key.productOrVariationID,
                                                                    images: handler.productImageStatuses.images)
        }
    }

    func reset() {
        statusUpdatesExcludedProductKeys = []
        statusUpdatesSubscriptions = []
        imageUploadSubscriptions = []
        activeUploadsPublisher = []

        imageStatusStorage.clearAllStatuses()

        actionHandlersByProduct = [:]
        imagesSaverByProduct = [:]
    }

    private func scheduleUploadInProgressNotificationIfNeeded() {
        if featureFlagService.isFeatureFlagEnabled(.backgroundProductImageUpload) {
            let statuses = imageStatusStorage.getAllStatuses()
            let hasUploadingStatuses = statuses.contains { $0.isUploading }

            if hasUploadingStatuses {
                let notification = LocalNotification(scenario: .productImageBackgroundUpload)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                Task {
                    await LocalNotificationScheduler(pushNotesManager: ServiceLocator.pushNotesManager).schedule(notification: notification,
                                                                                                                trigger: trigger, remoteFeatureFlag: nil)
                }
            }
        } else {
            guard !activeUploadsPublisher.isEmpty else { return }

            let notification = LocalNotification(scenario: .productImageBackgroundUpload)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            Task {
                await LocalNotificationScheduler(pushNotesManager: ServiceLocator.pushNotesManager).schedule(notification: notification,
                                                                                                             trigger: trigger, remoteFeatureFlag: nil)
            }
        }
    }

    @objc private func appDidEnterBackground() {
        self.scheduleUploadInProgressNotificationIfNeeded()
    }
}

private extension ProductImageUploader {
    /// Called to replace the local product ID with remote product ID for the previously uploaded images
    ///
    func updateProductIDOfImagesUploadedUsingLocalProductID(siteID: Int64,
                                                            productOrVariationID: ProductOrVariationID,
                                                            images: [ProductImage]) {
        images.forEach { image in
            Task {
                _ = try? await imagesProductIDUpdater.updateImageProductID(siteID: siteID,
                                                                           productID: productOrVariationID.id,
                                                                           productImage: image)
            }
        }
    }

    func observeStatusUpdates(key: Key, actionHandler: ProductImageActionHandler) {
        let observationToken = actionHandler.addUpdateObserver(self) { [weak self] productImageStatuses in
            guard let self = self else { return }

            if featureFlagService.isFeatureFlagEnabled(.backgroundProductImageUpload) {
                // Update the states in userDefaultsStatuses
                self.imageStatusStorage.appendStatuses(productImageStatuses, for: key.siteID, productID: key.productOrVariationID)
            }
            else {
                if !activeUploadsPublisher.contains(key), productImageStatuses.hasPendingUpload {
                    activeUploadsPublisher.append(key)
                } else if activeUploadsPublisher.contains(key), !productImageStatuses.hasPendingUpload {
                    /// When all pending uploads are completed or removed,
                    /// remove the key from active uploads
                    removeProductFromActiveUploads(key: key)
                }
            }
        }
        statusUpdatesSubscriptions.insert(observationToken)
    }

    func observeImageUploads(key: Key, actionHandler: ProductImageActionHandler) {
        let observationToken = actionHandler.addAssetUploadObserver(self) { [weak self] asset, result in
            guard let self else { return }

            if case .failure(let error) = result {
                let infoError = ProductImageUploadErrorInfo(siteID: key.siteID,
                                                            productOrVariationID: key.productOrVariationID,
                                                            error: .failedUploadingImage(asset: asset, error: error))
                if statusUpdatesExcludedProductKeys.contains(key) == false {
                    if !self.featureFlagService.isFeatureFlagEnabled(.backgroundProductImageUpload) {
                        // Only send the error directly if `backgroundProductImageUpload` feature flag is disabled
                        errorsSubject.send(infoError)
                    }
                    // To keep in mind
                    // Do not update storage here as the action handler will update its status
                    // which will trigger `observeStatusUpdates` to do the storage update
                }
            }
        }
        imageUploadSubscriptions.insert(observationToken)
    }

    func removeProductFromActiveUploads(key: Key) {
        if featureFlagService.isFeatureFlagEnabled(.backgroundProductImageUpload) {
            imageStatusStorage.removeStatus(where: { status in
                status.siteID == key.siteID &&
                status.productOrVariationID == key.productOrVariationID &&
                status.isUploading
            })
        } else {
            activeUploadsPublisher.removeAll(where: { $0 == key })
        }
    }
}

private extension ProductOrVariationID {
    func replacingID(_ id: Int64) -> ProductOrVariationID {
        switch self {
        case .product:
            return .product(id: id)
        case .variation(let productID, _):
            return .variation(productID: productID, variationID: id)
        }
    }
}

/// Possible errors from background image upload.
enum ProductImageUploaderError: Error {
    case noActionHandlerFound
    case noRemoteProductIDFound
    case failedSavingProductAfterImageUpload(error: Error)
    case failedUploadingImage(asset: ProductImageAssetType, error: Error)
}

private enum Localization {
    static let backgroundUploadNoticeTitle = NSLocalizedString(
        "productImageUploader.backgroundUploadNotice.title",
        value: "Image uploading will continue in the background",
        comment: ""
    )
}

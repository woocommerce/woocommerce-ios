import Combine
import Foundation
import struct Yosemite.ProductImage
import enum Yosemite.ProductAction
import protocol Yosemite.StoresManager

/// Information about a background product image upload error.
struct ProductImageUploadErrorInfo {
    let siteID: Int64
    let productOrVariationID: ProductOrVariationID
    let productImageStatuses: [ProductImageStatus]
    let error: ProductImageUploaderError
}

/// Identifiable data about a product or product variation.
enum ProductOrVariationID: Equatable, Hashable {
    case product(id: Int64)
    case variation(productID: Int64, variationID: Int64)

    /// Returns the product ID for product type and variation ID for variation type.
    var id: Int64 {
        switch self {
        case .product(let id):
            return id
        case .variation(_, let variationID):
            return variationID
        }
    }
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
    var errors: AnyPublisher<ProductImageUploadErrorInfo, Never> {
        errorsSubject.eraseToAnyPublisher()
    }

    var activeUploads: AnyPublisher<[ProductImageUploaderKey], Never> {
        $activeUploadsPublisher.eraseToAnyPublisher()
    }

    typealias Key = ProductImageUploaderKey

    private let errorsSubject: PassthroughSubject<ProductImageUploadErrorInfo, Never> = .init()
    private var statusUpdatesExcludedProductKeys: Set<Key> = []
    private var statusUpdatesSubscriptions: Set<AnyCancellable> = []

    private var actionHandlersByProduct: [Key: ProductImageActionHandler] = [:]
    private var imagesSaverByProduct: [Key: ProductImagesSaver] = [:]

    @Published private var activeUploadsPublisher: [ProductImageUploaderKey] = []

    private let stores: StoresManager
    private let imagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol

    init(stores: StoresManager = ServiceLocator.stores,
         imagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol = ProductImagesProductIDUpdater()) {
        self.stores = stores
        self.imagesProductIDUpdater = imagesProductIDUpdater
    }

    func actionHandler(key: ProductImageUploaderKey, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        let actionHandler: ProductImageActionHandler
        if let handler = actionHandlersByProduct[key] {
            actionHandler = handler
        } else {
            actionHandler = ProductImageActionHandler(siteID: key.siteID, productID: key.productOrVariationID, imageStatuses: originalStatuses, stores: stores)
            actionHandlersByProduct[key] = actionHandler
            observeStatusUpdates(key: key, actionHandler: actionHandler)
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
        if activeUploadsPublisher.contains(key) {
            let notice = Notice(title: Localization.backgroundUploadNoticeTitle)
            noticePresenter.enqueue(notice: notice)
        }
    }

    func hasUnsavedChangesOnImages(key: ProductImageUploaderKey, originalImages: [ProductImage]) -> Bool {
        guard let handler = actionHandlersByProduct[key] else {
            return false
        }
        let productImagesSaver = imagesSaverByProduct[key]

        if let productImagesSaver, productImagesSaver.imageStatusesToSave.isNotEmpty {
            // If there are images scheduled to be saved, there are no unsaved changes if the image statuses to save match the latest image statuses.
            return handler.productImageStatuses != productImagesSaver.imageStatusesToSave
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
                                              productImageStatuses: handler.productImageStatuses,
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
        activeUploadsPublisher = []

        actionHandlersByProduct = [:]
        imagesSaverByProduct = [:]
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
        let observationToken = actionHandler.addUpdateObserver(self) { [weak self] (productImageStatuses, error) in
            guard let self = self else { return }

            if !activeUploadsPublisher.contains(key), productImageStatuses.hasPendingUpload {
                activeUploadsPublisher.append(key)
            } else if activeUploadsPublisher.contains(key), !productImageStatuses.hasPendingUpload {
                /// When all pending uploads are completed or removed,
                /// remove the key from active uploads
                removeProductFromActiveUploads(key: key)
            }

            if let error = error, statusUpdatesExcludedProductKeys.contains(key) == false {
                removeProductFromActiveUploads(key: key)
                errorsSubject.send(.init(siteID: key.siteID,
                                         productOrVariationID: key.productOrVariationID,
                                         productImageStatuses: productImageStatuses,
                                         error: .failedUploadingImage(error: error)))
            }
        }
        statusUpdatesSubscriptions.insert(observationToken)
    }

    func removeProductFromActiveUploads(key: Key) {
        activeUploadsPublisher.removeAll(where: { $0 == key })
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
    case failedUploadingImage(error: Error)
}

private enum Localization {
    static let backgroundUploadNoticeTitle = NSLocalizedString(
        "productImageUploader.backgroundUploadNotice.title",
        value: "Image uploading will continue in the background",
        comment: ""
    )
}

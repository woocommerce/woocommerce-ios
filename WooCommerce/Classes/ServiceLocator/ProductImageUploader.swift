import Combine
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
}

/// Identifiable information about a specific product or product variation of different sites for image upload.
struct ProductImageUploaderKey: Equatable, Hashable {
    let siteID: Int64
    let productOrVariationID: ProductOrVariationID
    let isLocalID: Bool
}

/// Handles product image upload to support background image upload.
protocol ProductImageUploaderProtocol {
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

    typealias Key = ProductImageUploaderKey

    private let errorsSubject: PassthroughSubject<ProductImageUploadErrorInfo, Never> = .init()
    private var statusUpdatesExcludedProductKeys: Set<Key> = []
    private var statusUpdatesSubscriptions: Set<AnyCancellable> = []

    private var actionHandlersByProduct: [Key: ProductImageActionHandler] = [:]
    private var imagesSaverByProduct: [Key: ProductImagesSaver] = [:]
    private let stores: StoresManager
    private let imagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol

    init(stores: StoresManager = ServiceLocator.stores,
         imagesProductIDUpdater: ProductImagesProductIDUpdaterProtocol = ProductImagesProductIDUpdater()) {
        self.stores = stores
        self.imagesProductIDUpdater = imagesProductIDUpdater
    }

    func actionHandler(key: ProductImageUploaderKey, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        let actionHandler: ProductImageActionHandler
        if let handler = actionHandlersByProduct[key], handler.productImageStatuses.hasPendingUpload {
            actionHandler = handler
        } else {
            actionHandler = ProductImageActionHandler(siteID: key.siteID, productID: key.productOrVariationID, imageStatuses: originalStatuses, stores: stores)
            actionHandlersByProduct[key] = actionHandler
            observeStatusUpdatesForErrors(key: key, actionHandler: actionHandler)
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
        handler.updateProductID(remoteID)

        actionHandlersByProduct.removeValue(forKey: key)
        let keyWithRemoteProductID = Key(siteID: siteID,
                                         productOrVariationID: localID.replacingID(remoteID),
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

    func hasUnsavedChangesOnImages(key: ProductImageUploaderKey, originalImages: [ProductImage]) -> Bool {
        guard let handler = actionHandlersByProduct[key] else {
            return false
        }
        if let productImagesSaver = imagesSaverByProduct[key], productImagesSaver.imageStatusesToSave.isNotEmpty {
            // If there are images scheduled to be saved, there are no unsaved changes if the image statuses to save match the latest image statuses.
            return handler.productImageStatuses != productImagesSaver.imageStatusesToSave
        } else {
            // Otherwise, there are unsaved changes if there is any pending image upload or any difference in the remote image IDs between the
            // original and latest product.
            return handler.productImageStatuses.hasPendingUpload ||
            handler.productImageStatuses.images.map { $0.imageID } != originalImages.map { $0.imageID }
        }
    }

    func saveProductImagesWhenNoneIsPendingUploadAnymore(key: ProductImageUploaderKey,
                                                         onProductSave: @escaping (Result<[ProductImage], Error>) -> Void) {
        // The product has to exist remotely in order to save its images remotely.
        // In product creation, this save function should be called after a new product is saved remotely for the first time.
        guard key.isLocalID == false else {
            return
        }

        guard let handler = actionHandlersByProduct[key] else {
            return
        }

        guard handler.productImageStatuses.hasPendingUpload else {
            updateProductIDOfImagesUploadedUsingLocalProductID(siteID: siteID,
                                                               productID: productID,
                                                               images: handler.productImageStatuses.images)
            return
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
            self.updateProductIDOfImagesUploadedUsingLocalProductID(siteID: siteID,
                                                                     productID: productID,
                                                                     images: handler.productImageStatuses.images)
        }
    }

    func reset() {
        statusUpdatesExcludedProductKeys = []
        statusUpdatesSubscriptions = []

        actionHandlersByProduct = [:]
        imagesSaverByProduct = [:]
    }
}

private extension ProductImageUploader {
    /// Called to replace the local product ID with remote product ID for the previously uploaded images
    ///
    func updateProductIDOfImagesUploadedUsingLocalProductID(siteID: Int64,
                                                            productID: Int64,
                                                            images: [ProductImage]) {
        images.forEach { image in
            Task {
                _ = try? await imagesProductIDUpdater.updateImageProductID(siteID: siteID,
                                                                      productID: productID,
                                                                      productImage: image)
            }
        }
    }

    private func observeStatusUpdatesForErrors(key: Key, actionHandler: ProductImageActionHandler) {
        let observationToken = actionHandler.addUpdateObserver(self) { [weak self] (productImageStatuses, error) in
            guard let self = self else { return }

            if let error = error, self.statusUpdatesExcludedProductKeys.contains(key) == false {
                self.errorsSubject.send(.init(siteID: key.siteID,
                                              productOrVariationID: key.productOrVariationID,
                                              productImageStatuses: productImageStatuses,
                                              error: .failedUploadingImage(error: error)))
            }
        }
        statusUpdatesSubscriptions.insert(observationToken)
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
    case failedSavingProductAfterImageUpload(error: Error)
    case failedUploadingImage(error: Error)
}

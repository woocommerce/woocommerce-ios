import Combine
import struct Yosemite.ProductImage
import enum Yosemite.ProductAction
import protocol Yosemite.StoresManager

struct ProductImageUploadUpdate {
    let siteID: Int64
    let productID: Int64
    let productImageStatuses: [ProductImageStatus]
    let error: Error?
}

protocol ProductImageUploaderProtocol {
    var statusUpdates: AnyPublisher<ProductImageUploadUpdate, Never> { get }
    func actionHandler(siteID: Int64, productID: Int64, isLocalID: Bool, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler
    func updateProductID(siteID: Int64, localProductID: Int64, remoteProductID: Int64)
    func cancelImageUpload()
}

final class ProductImageUploader: ProductImageUploaderProtocol {
    var statusUpdates: AnyPublisher<ProductImageUploadUpdate, Never> {
        statusUpdatesSubject.eraseToAnyPublisher()
    }

    private let statusUpdatesSubject: PassthroughSubject<ProductImageUploadUpdate, Never> = .init()

    private struct ProductKey: Equatable, Hashable {
        let siteID: Int64
        let productID: Int64
        let isLocalID: Bool
    }

    private var actionHandlersByProduct: [ProductKey: ProductImageActionHandler] = [:]
    private var pendingUploadStatesByProduct: [ProductKey: Bool] = [:]
    private let stores: StoresManager

    init(stores: StoresManager = ServiceLocator.stores) {
        self.stores = stores
    }

    func actionHandler(siteID: Int64, productID: Int64, isLocalID: Bool, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler {
        let key = ProductKey(siteID: siteID, productID: productID, isLocalID: isLocalID)
        let actionHandler: ProductImageActionHandler
        if let handler = actionHandlersByProduct[key], handler.productImageStatuses.hasPendingUpload {
            actionHandler = handler
        } else {
            actionHandler = ProductImageActionHandler(siteID: siteID, productID: productID, imageStatuses: originalStatuses)
            actionHandlersByProduct[key] = actionHandler
        }
        observeStatusUpdatesToUpdateProduct(key: key, actionHandler: actionHandler)
        return actionHandler
    }

    func updateProductID(siteID: Int64, localProductID: Int64, remoteProductID: Int64) {
        let key = ProductKey(siteID: siteID, productID: localProductID, isLocalID: true)
        guard let handler = actionHandlersByProduct[key] else {
            return
        }
        actionHandlersByProduct.removeValue(forKey: key)
        let keyWithRemoteProductID = ProductKey(siteID: siteID, productID: remoteProductID, isLocalID: false)
        actionHandlersByProduct[keyWithRemoteProductID] = handler
        observeStatusUpdatesToUpdateProduct(key: keyWithRemoteProductID, actionHandler: handler)
        // TODO: update `parent_id` of previously uploaded media, might have to track uploaded images like adding a boolean to `ProductImageStatus.remote`
        // Ref: https://developer.wordpress.com/docs/api/1.1/post/sites/%24site/media/%24media_ID/
    }

    func cancelImageUpload() {
        actionHandlersByProduct.values.forEach { actionHandler in
            // TODO: add cancel support
        }
    }
}

private extension ProductImageUploader {
    private func observeStatusUpdatesToUpdateProduct(key: ProductKey, actionHandler: ProductImageActionHandler) {
        var observationToken: AnyCancellable?
        observationToken = actionHandler.addUpdateObserver(self) { [weak self] (productImageStatuses, error) in
            guard let self = self else { return }

            if let error = error {
                self.statusUpdatesSubject.send(.init(siteID: key.siteID, productID: key.productID, productImageStatuses: productImageStatuses, error: error))
            }

            let hasPendingUploadBefore = self.pendingUploadStatesByProduct[key]
            self.pendingUploadStatesByProduct[key] = productImageStatuses.hasPendingUpload

            guard productImageStatuses.hasPendingUpload == false && hasPendingUploadBefore == true,
                  productImageStatuses.images.isNotEmpty,
                  key.isLocalID == false else {
                return
            }

            let action = ProductAction.updateProductImages(siteID: key.siteID,
                                                           productID: key.productID,
                                                           images: productImageStatuses.images) { [weak self] result in
                guard let self = self else { return }
                self.statusUpdatesSubject.send(.init(siteID: key.siteID, productID: key.productID, productImageStatuses: productImageStatuses, error: nil))
            }
            self.stores.dispatch(action)

            observationToken?.cancel()
        }
    }
}

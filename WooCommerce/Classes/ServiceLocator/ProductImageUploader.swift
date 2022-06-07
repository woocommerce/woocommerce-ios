import struct Yosemite.ProductImage
import enum Yosemite.ProductAction
import protocol Yosemite.StoresManager

/// Handles product image upload to support background image upload.
protocol ProductImageUploaderProtocol {
    /// Called for product image upload use cases (e.g. product/variation form, downloadable product list).
    /// - Parameters:
    ///   - siteID: the ID of the site where images are uploaded to.
    ///   - productID: the ID of the product where images are added to.
    ///   - isLocalID: whether the product ID is a local ID like in product creation.
    ///   - originalStatuses: the current image statuses of the product for initialization.
    func actionHandler(siteID: Int64, productID: Int64, isLocalID: Bool, originalStatuses: [ProductImageStatus]) -> ProductImageActionHandler
}

/// Supports background image upload and product images update after the user leaves the product form.
final class ProductImageUploader: ProductImageUploaderProtocol {
    private struct ProductKey: Equatable, Hashable {
        let siteID: Int64
        let productID: Int64
        let isLocalID: Bool
    }

    private var actionHandlersByProduct: [ProductKey: ProductImageActionHandler] = [:]
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
            actionHandler = ProductImageActionHandler(siteID: siteID, productID: productID, imageStatuses: originalStatuses, stores: stores)
            actionHandlersByProduct[key] = actionHandler
        }
        return actionHandler
    }
}

import Combine

struct ProductImageUploadUpdate {
    let siteID: Int64
    let productID: Int64
    let productImageStatuses: [ProductImageStatus]
    let error: Error?
}

protocol ProductImageUploaderProtocol {
    var statusUpdates: AnyPublisher<ProductImageUploadUpdate, Never> { get }
    func actionHandler(siteID: Int64, productID: Int64) -> ProductImageActionHandler
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
    }

    private var actionHandlersByProduct: [ProductKey: ProductImageActionHandler] = [:]

    func actionHandler(siteID: Int64, productID: Int64) -> ProductImageActionHandler {
        let key = ProductKey(siteID: siteID, productID: productID)
        guard let handler = actionHandlersByProduct[key] else {
            let handler = ProductImageActionHandler(siteID: siteID, productID: productID, imageStatuses: [])
            actionHandlersByProduct[key] = handler
            return handler
        }
        return handler
    }

    func updateProductID(siteID: Int64, localProductID: Int64, remoteProductID: Int64) {
        let key = ProductKey(siteID: siteID, productID: localProductID)
        guard let handler = actionHandlersByProduct[key] else {
            return
        }
        actionHandlersByProduct.removeValue(forKey: key)
        let keyWithRemoteProductID = ProductKey(siteID: siteID, productID: remoteProductID)
        actionHandlersByProduct[keyWithRemoteProductID] = handler
    }

    func cancelImageUpload() {
        actionHandlersByProduct.values.forEach { actionHandler in
            // TODO: add cancel support
//            actionHandler.resetProductImages(to: <#T##ProductFormDataModel#>)
        }
    }
}

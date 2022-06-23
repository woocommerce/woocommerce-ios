import Combine
import Yosemite

final class ProductImagesProductIDUpdater {
    private let siteID: Int64
    private let productID: Int64
    private let stores: StoresManager

    init(siteID: Int64, productID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.productID = productID
        self.stores = stores
    }

    func updateProductIDOfImages(_ productImages: [ProductImage]) {
        productImages.forEach { productImage in
            updateProductIDFor(productImageID: productImage.imageID,
                               siteID: siteID,
                               productID: productID) { result in
                switch result {
                case .failure(let error):
                    DDLogError("⛔️ Error updating `parent_id` of media with \(productImage.imageID): \(error)")
                default:
                    break
                }
            }
        }
    }
}

private extension ProductImagesProductIDUpdater {
    func updateProductIDFor(productImageID: Int64,
                            siteID: Int64,
                            productID: Int64,
                            onCompletion: @escaping (Result<Media, Error>) -> Void) {
        let action = MediaAction.updateProductID(siteID: siteID, productID: productID, mediaID: productImageID) { result in
            onCompletion(result)
        }
        stores.dispatch(action)
    }
}

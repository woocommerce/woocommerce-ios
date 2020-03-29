import Foundation
import Networking
import Storage

// MARK: - ProductCategoryStore
//
public final class ProductCategoryStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductCategoryAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ProductCategoryAction else {
            assertionFailure("ProductCategoryStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveProductCategories(let siteID, let pageNumber, let pageSize, let onCompletion):
            synchronizeProductCategories(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services
//
private extension ProductCategoryStore {

    /// Retrieve all product categories associated with a given Site ID.
    ///
    func synchronizeProductCategories(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping ([ProductCategory]?, Error?) -> Void) {
        let remote = ProductCategoriesRemote(network: network)

        remote.loadAllProductCategories(for: siteID, pageNumber: pageNumber, pageSize: pageSize) { (productCategories, error) in
            guard let productCategories = productCategories else {
                onCompletion(nil, error)
                return
            }

            // TODO-2000 Insert product categories into Storage.framework
            onCompletion(productCategories, nil)
        }
    }
}

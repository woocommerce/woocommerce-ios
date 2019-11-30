import Foundation
import Networking
import Storage

// MARK: - ProductShippingClassStore
//
public final class ProductShippingClassStore: Store {

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductShippingClassAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ProductShippingClassAction else {
            assertionFailure("ProductReviewStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeProductShippingClassModels(let siteID, let pageNumber, let pageSize, let onCompletion):
            synchronizeProductShippingClasses(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductShippingClassStore {

    /// Synchronizes the product reviews associated with a given Site ID (if any!).
    ///
    func synchronizeProductShippingClasses(siteID: Int64, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductShippingClassRemote(network: network)

        remote.loadAllProductShippingClasses(for: siteID) { [weak self] (productShippingClasses, error) in
            guard let productShippingClasses = productShippingClasses else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductShippingClassesInBackground(readOnlyProductShippingClasses: productShippingClasses,
                                                                 siteID: siteID) {
                                                                    onCompletion(nil)
            }
        }
    }
}


// MARK: - Storage: ProductReview
//
private extension ProductShippingClassStore {

    /// Updates (OR Inserts) the specified ReadOnly ProductReview Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredProductShippingClassesInBackground(readOnlyProductShippingClasses: [Networking.ProductShippingClass],
                                                   siteID: Int64,
                                                   onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform { [weak self] in
            self?.upsertStoredProductShippingClasses(readOnlyProductShippingClasses: readOnlyProductShippingClasses, in: derivedStorage, siteID: siteID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}


private extension ProductShippingClassStore {
    /// Updates (OR Inserts) the specified ReadOnly ProductShippingClass Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProductShippingClasses: Remote ProductShippingClass's to be persisted.
    ///     - storage: Where we should save all the things!
    ///     - siteID: site ID for looking up the Product.
    ///     - productID: product ID for looking up the Product.
    ///
    func upsertStoredProductShippingClasses(readOnlyProductShippingClasses: [Networking.ProductShippingClass],
                                       in storage: StorageType,
                                       siteID: Int64) {
        // Upserts the Product Variations from the read-only version
        for readOnlyProductShippingClass in readOnlyProductShippingClasses {
            let storageProductShippingClass = storage.loadProductShippingClass(siteID: siteID,
                                                                               shippingClassID: readOnlyProductShippingClass.shippingClassID)
                ?? storage.insertNewObject(ofType: Storage.ProductShippingClass.self)
            storageProductShippingClass.update(with: readOnlyProductShippingClass)
        }
    }
}

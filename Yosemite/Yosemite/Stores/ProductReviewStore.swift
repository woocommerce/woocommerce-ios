import Foundation
import Networking
import Storage


// MARK: - ProductReviewStore
//
public final class ProductReviewStore: Store {

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? ProductReviewAction else {
            assertionFailure("ProductReviewStore received an unsupported action")
            return
        }

        switch action {
        case .resetStoredProductReviews(let onCompletion):
            resetStoredProductReviews(onCompletion: onCompletion)
        case .synchronizeProductReviews(let siteID, let pageNumber, let pageSize, let onCompletion):
            synchronizeProductReviews(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .retrieveProductReview(let siteID, let reviewID, let onCompletion):
            retrieveProductReview(siteID: siteID, reviewID: reviewID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductReviewStore {

    /// Deletes all of the Stored ProductReviews.
    ///
    func resetStoredProductReviews(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.ProductReview.self)
        storage.saveIfNeeded()
        DDLogDebug("Product Reviews deleted")

        onCompletion()
    }

    /// Synchronizes the product reviews associated with a given Site ID (if any!).
    ///
    func synchronizeProductReviews(siteID: Int, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ProductReviewsRemote(network: network)

        remote.loadAllProductReviews(for: siteID) { [weak self] (productReviews, error) in
            guard let productReviews = productReviews else {
                onCompletion(error)
                return
            }

            self?.upsertStoredProductReviewsInBackground(readOnlyProductReviews: productReviews) {
                onCompletion(nil)
            }
        }
    }

    /// Retrieves the product review associated with a given siteID + reviewID (if any!).
    ///
    func retrieveProductReview(siteID: Int, reviewID: Int, onCompletion: @escaping (Networking.ProductReview?, Error?) -> Void) {
        let remote = ProductReviewsRemote(network: network)

        remote.loadProductReview(for: siteID, reviewID: reviewID) { [weak self] (productReview, error) in
            guard let productReview = productReview else {
                if case NetworkError.notFound? = error {
                    self?.deleteStoredProductReview(siteID: siteID, reviewID: reviewID)
                }
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredProductReviewsInBackground(readOnlyProductReviews: [productReview]) {
                onCompletion(productReview, nil)
            }
        }
    }
}


// MARK: - Storage: ProductReview
//
private extension ProductReviewStore {

    /// Deletes any Storage.ProductReview with the specified `siteID` and `reviewID`
    ///
    func deleteStoredProductReview(siteID: Int, reviewID: Int) {
        let storage = storageManager.viewStorage
        guard let productReview = storage.loadProductReview(siteID: siteID, reviewID: reviewID) else {
            return
        }

        storage.deleteObject(productReview)
        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified ReadOnly ProductReview Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredProductReviewsInBackground(readOnlyProductReviews: [Networking.ProductReview], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.upsertStoredProductReviews(readOnlyProductReviews: readOnlyProductReviews, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly ProductReview Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProductReviews: Remote ProductReviews to be persisted.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredProductReviews(readOnlyProductReviews: [Networking.ProductReview], in storage: StorageType) {
        for readOnlyProductReview in readOnlyProductReviews {
            let storageProductReview = storage.loadProductReview(siteID: readOnlyProductReview.siteID, reviewID: readOnlyProductReview.productID) ??
                storage.insertNewObject(ofType: Storage.ProductReview.self)

            //storageProduct.update(with: readOnlyProductReview)
        }
    }
}


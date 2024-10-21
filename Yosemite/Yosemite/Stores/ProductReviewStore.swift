import Foundation
import Networking
import Storage


// MARK: - ProductReviewStore
//
public final class ProductReviewStore: Store {
    private let remote: ProductReviewsRemote

    private lazy var productReviewFromNoteUseCase =
    RetrieveProductReviewFromNoteUseCase(network: network, storageManager: storageManager)

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = ProductReviewsRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: ProductReviewAction.self)
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
        case .synchronizeProductReviews(let siteID, let pageNumber, let pageSize, let products, let status, let onCompletion):
            synchronizeProductReviews(siteID: siteID,
                                      pageNumber: pageNumber,
                                      pageSize: pageSize,
                                      products: products,
                                      status: status,
                                      onCompletion: onCompletion)
        case .retrieveProductReview(let siteID, let reviewID, let onCompletion):
            retrieveProductReview(siteID: siteID, reviewID: reviewID, onCompletion: onCompletion)
        case .retrieveProductReviewFromNote(let noteID, let onCompletion):
            retrieveProductReviewFromNote(noteID: noteID, onCompletion: onCompletion)
        case .updateApprovalStatus(let siteID, let reviewID, let isApproved, let onCompletion):
            updateApprovalStatus(siteID: siteID, reviewID: reviewID, isApproved: isApproved, onCompletion: onCompletion)
        case .updateTrashStatus(let siteID, let reviewID, let isTrashed, let onCompletion):
            updateTrashStatus(siteID: siteID, reviewID: reviewID, isTrashed: isTrashed, onCompletion: onCompletion)
        case .updateSpamStatus(let siteID, let reviewID, let isSpam, let onCompletion):
            updateSpamStatus(siteID: siteID, reviewID: reviewID, isSpam: isSpam, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension ProductReviewStore {

    /// Deletes all of the Stored ProductReviews.
    ///
    func resetStoredProductReviews(onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            storage.deleteAllObjects(ofType: Storage.ProductReview.self)
        }, completion: {
            DDLogDebug("Product Reviews deleted")
            onCompletion()
        }, on: .main)
    }

    /// Synchronizes the product reviews associated with a given Site ID (if any!).
    ///
    func synchronizeProductReviews(siteID: Int64, pageNumber: Int, pageSize: Int, products: [Int64]? = nil, status: ProductReviewStatus? = nil,
                                   onCompletion: @escaping (Result<[ProductReview], Error>) -> Void) {
        remote.loadAllProductReviews(for: siteID,
                                     pageNumber: pageNumber,
                                     pageSize: pageSize,
                                     products: products,
                                     filterByStatuses: status.map { [$0] }) { [weak self] result in
            switch result {
            case .failure(let error):
                onCompletion(.failure(error))
            case .success(let productReviews):
                let shouldClearCache = pageNumber == Default.firstPageNumber
                self?.upsertStoredProductReviewsInBackground(readOnlyProductReviews: productReviews,
                                                             siteID: siteID,
                                                             shouldDeleteAllStoredProductReviews: shouldClearCache) {
                    onCompletion(.success(productReviews))
                }
            }
        }
    }

    /// Retrieves the product review associated with a given siteID + reviewID (if any!).
    ///
    func retrieveProductReview(siteID: Int64, reviewID: Int64, onCompletion: @escaping (Networking.ProductReview?, Error?) -> Void) {
        remote.loadProductReview(for: siteID, reviewID: reviewID) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .failure(let error):
                if case NetworkError.notFound = error {
                    self.deleteStoredProductReview(siteID: siteID, reviewID: reviewID) {
                        onCompletion(nil, error)
                    }
                } else {
                    onCompletion(nil, error)
                }
            case .success(let productReview):
                self.upsertStoredProductReviewsInBackground(readOnlyProductReviews: [productReview], siteID: siteID) {
                    onCompletion(productReview, nil)
                }
            }
        }
    }

    /// Retrieves the `Note`, `ProductReview`, and `Product` in sequence.
    ///
    /// Only the `ProductReview` is stored in the database. Please see
    /// `RetrieveProductReviewFromNoteUseCase` for the reason why.
    ///
    func retrieveProductReviewFromNote(noteID: Int64,
                                       onCompletion: @escaping (Result<ProductReviewFromNoteParcel, Error>) -> Void) {
        productReviewFromNoteUseCase.retrieve(noteID: noteID, completion: onCompletion)
    }

    /// Updates the review's approval status
    ///
    func updateApprovalStatus(siteID: Int64, reviewID: Int64, isApproved: Bool, onCompletion: @escaping (ProductReviewStatus?, Error?) -> Void) {
        let newStatus = isApproved ? ProductReviewStatus.approved : ProductReviewStatus.hold
        moderateReview(siteID: siteID, reviewID: reviewID, status: newStatus, onCompletion: onCompletion)
    }

    /// Updates the review's trash status
    ///
    func updateTrashStatus(siteID: Int64, reviewID: Int64, isTrashed: Bool, onCompletion: @escaping (ProductReviewStatus?, Error?) -> Void) {
        let newStatus = isTrashed ? ProductReviewStatus.trash : ProductReviewStatus.untrash
        moderateReview(siteID: siteID, reviewID: reviewID, status: newStatus, onCompletion: onCompletion)
    }

    /// Updates the review's spam status
    ///
    func updateSpamStatus(siteID: Int64, reviewID: Int64, isSpam: Bool, onCompletion: @escaping (ProductReviewStatus?, Error?) -> Void) {
        let newStatus = isSpam ? ProductReviewStatus.spam : ProductReviewStatus.unspam
        moderateReview(siteID: siteID, reviewID: reviewID, status: newStatus, onCompletion: onCompletion)
    }
}


// MARK: - Storage: ProductReview
//
private extension ProductReviewStore {

    /// Deletes any Storage.ProductReview with the specified `siteID` and `reviewID`
    ///
    func deleteStoredProductReview(siteID: Int64, reviewID: Int64, onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            guard let productReview = storage.loadProductReview(siteID: siteID, reviewID: reviewID) else {
                DDLogError("⛔️ Cannot find the product review with the given ID to delete from storage!")
                return
            }
            storage.deleteObject(productReview)
        }, completion: onCompletion, on: .main)
    }

    /// Updates (OR Inserts) the specified ReadOnly ProductReview Entities *in a background thread*. onCompletion will be called
    /// on the main thread!
    ///
    func upsertStoredProductReviewsInBackground(readOnlyProductReviews: [Networking.ProductReview],
                                                siteID: Int64,
                                                shouldDeleteAllStoredProductReviews: Bool = false,
                                                onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ [weak self] storage in
            if shouldDeleteAllStoredProductReviews {
                storage.deleteProductReviews(siteID: siteID)
            }
            self?.upsertStoredProductReviews(readOnlyProductReviews: readOnlyProductReviews, in: storage, siteID: siteID)
        }, completion: onCompletion, on: .main)
    }

    func moderateReview(siteID: Int64, reviewID: Int64, status: ProductReviewStatus, onCompletion: @escaping (ProductReviewStatus?, Error?) -> Void) {
        remote.updateProductReviewStatus(for: siteID, reviewID: reviewID, statusKey: status.rawValue) { [weak self] (productReview, error) in
            guard let self, let productReview else {
                onCompletion(nil, error)
                return
            }

            storageManager.performAndSave({ storage in
                if let existingStorageProductReview = storage.loadProductReview(siteID: siteID, reviewID: reviewID) {
                    existingStorageProductReview.update(with: productReview)
                }
            }, completion: {
                onCompletion(productReview.status, nil)
            }, on: .main)
        }
    }
}


extension ProductReviewStore {
    /// Updates (OR Inserts) the specified ReadOnly ProductReview Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyProductReviews: Remote ProductReviews to be persisted.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredProductReviews(readOnlyProductReviews: [Networking.ProductReview], in storage: StorageType, siteID: Int64) {
        // Upsert the Product reviews from the read-only reviews
        for readOnlyProductReview in readOnlyProductReviews {
            let storageProductReview = storage.loadProductReview(siteID: siteID, reviewID: readOnlyProductReview.reviewID) ??
                storage.insertNewObject(ofType: Storage.ProductReview.self)
            storageProductReview.update(with: readOnlyProductReview)
        }
    }
}

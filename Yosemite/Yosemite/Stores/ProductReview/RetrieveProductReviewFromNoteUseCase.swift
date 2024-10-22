
import Foundation
import Networking
import protocol Storage.StorageManagerType

/// Fetches the `Note`, `ProductReview`, and `Product` in sequence from the Storage and/or API
/// using a `noteID`.
///
/// This can be used to present a view when a push notification is received. This should only
/// be used as part of `ProductReviewStore`.
///
/// ## Saving
///
/// Only the `ProductReview` is saved to the database for now. This is to avoid possible
/// conflicts if a scenario like this happens:
///
/// 1. This UseCase is executed.
/// 2. A `Product` sync is also happening in the background.
///
/// Because the `Product` sync in `ProductStore` is using its own child/derived `StorageType`
/// (`NSManagedObjectContext`), this could mean that `ProductStore` and this `UseCase`
/// could have separate snapshots and would think that **the same** `Product` does not
/// currently exist in the database. Both would end up saving the same `Product` and we'll
/// show duplicate products to the user.
///
/// ## Site ID
///
/// The `siteID` is automatically determined from the fetched `Note` (`noteID`).
///
final class RetrieveProductReviewFromNoteUseCase {
    typealias CompletionBlock = (Result<ProductReviewFromNoteParcel, Error>) -> Void
    private typealias AbortBlock = (Error) -> Void

    /// Custom errors raised by self. Networking `Errors` are re-raised.
    ///
    enum ProductReviewFromNoteRetrieveError: Error {
        case notificationNotFound
        case reviewNotFound
        case storageNoLongerAvailable
    }

    private let notificationsRemote: NotificationsRemoteProtocol
    private let productReviewsRemote: ProductReviewsRemoteProtocol
    private let productsRemote: ProductsRemoteProtocol

    /// Storage Layer
    /// We should use `weak` because we have to guarantee that we will not do any saving if this
    /// `StorageManagerType` is deallocated, which is part of the `ProductReviewStore` lifecycle.
    ///
    private weak var storageManager: StorageManagerType?

    /// Create an instance of self.
    ///
    init(notificationsRemote: NotificationsRemoteProtocol,
         productReviewsRemote: ProductReviewsRemoteProtocol,
         productsRemote: ProductsRemoteProtocol,
         storageManager: StorageManagerType) {
        self.notificationsRemote = notificationsRemote
        self.productReviewsRemote = productReviewsRemote
        self.productsRemote = productsRemote
        self.storageManager = storageManager
    }

    /// Create an instance of self.
    ///
    convenience init(network: Network, storageManager: StorageManagerType) {
        self.init(notificationsRemote: NotificationsRemote(network: network),
                  productReviewsRemote: ProductReviewsRemote(network: network),
                  productsRemote: ProductsRemote(network: network),
                  storageManager: storageManager)
    }

    /// Retrieve the `Note`, `ProductReview`, and `Product` based on the given `noteID`.
    ///
    func retrieve(noteID: Int64, completion: @escaping CompletionBlock) {
        let abort: (Error) -> () = {
            completion(.failure($0))
        }

        // Do not use `weak self` because we want to retain this class
        // until all the callbacks are finished.
        fetchNote(noteID: noteID, abort: abort) { note in
            self.fetchProductReview(from: note, abort: abort) { review in
                self.saveProductReview(review, abort: abort) {
                    self.fetchProduct(siteID: review.siteID, productID: review.productID, abort: abort, next: { product in
                        let parcel = ProductReviewFromNoteParcel(note: note, review: review, product: product)
                        completion(.success(parcel))
                    })
                }
            }
        }
    }

    /// Fetch the `Note` from storage, or from the API if it is not available in storage.
    ///
    private func fetchNote(noteID: Int64,
                           abort: @escaping AbortBlock,
                           next: @escaping (Note) -> Void) {
        if let noteInStorage = storageManager?.viewStorage.loadNotification(noteID: noteID) {
            return next(noteInStorage.toReadOnly())
        }

        notificationsRemote.loadNotes(noteIDs: [noteID], pageSize: nil) { result in
            switch result {
            case .failure(let error):
                abort(error)
            case .success(let notes):
                guard let note = notes.first else {
                    return abort(ProductReviewFromNoteRetrieveError.notificationNotFound)
                }

                next(note)
            }
        }
    }

    /// Fetch the `ProductReview` from storage, or from the API if it is not available in storage.
    ///
    private func fetchProductReview(from note: Note,
                                    abort: @escaping AbortBlock,
                                    next: @escaping (ProductReview) -> Void) {
        guard let siteID = note.meta.identifier(forKey: .site),
            let reviewID = note.meta.identifier(forKey: .comment) else {
                return abort(ProductReviewFromNoteRetrieveError.reviewNotFound)
        }

        if let productReviewInStorage = storageManager?.viewStorage.loadProductReview(siteID: Int64(siteID), reviewID: Int64(reviewID)) {
            return next(productReviewInStorage.toReadOnly())
        }

        productReviewsRemote.loadProductReview(for: Int64(siteID), reviewID: Int64(reviewID)) { result in
            switch result {
            case .failure(let error):
                abort(error)
            case .success(let review):
                next(review)
            }
        }
    }

    /// Save the given ProductReview to the database.
    ///
    private func saveProductReview(_ review: ProductReview,
                                   abort: @escaping AbortBlock,
                                   next: @escaping () -> Void) {
        guard let storageManager else {
            return abort(ProductReviewFromNoteRetrieveError.storageNoLongerAvailable)
        }
        storageManager.performAndSave({ storage in
            let storageReview = storage.loadProductReview(siteID: review.siteID, reviewID: review.reviewID)
                ?? storage.insertNewObject(ofType: StorageProductReview.self)
            storageReview.update(with: review)
        }, completion: next, on: .main)
    }

    /// Fetch the `Product` from storage, or from the API if it is not available in storage.
    ///
    private func fetchProduct(siteID: Int64,
                              productID: Int64,
                              abort: @escaping AbortBlock,
                              next: @escaping (Product) -> Void) {
        if let productInStorage = storageManager?.viewStorage.loadProduct(siteID: siteID, productID: productID) {
            return next(productInStorage.toReadOnly())
        }

        productsRemote.loadProduct(for: siteID, productID: productID) { result in
            switch result {
            case .failure(let error):
                abort(error)
            case .success(let product):
                next(product)
            }
        }
    }
}

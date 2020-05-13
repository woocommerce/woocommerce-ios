
import Foundation
import Networking
import protocol Storage.StorageType

public struct ProductReviewFromNoteParcel {
    public let note: Note
    public let review: ProductReview
    public let product: Product
}

/// Fetches the `Note`, `ProductReview`, and `Product` in sequence from the API using a `noteID`.
///
/// This can be used to present a view when a push notification is received.
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
/// Perhaps in the future we can make it possible to _share_ these `StorageType` instances
/// behind a well-protected abstraction so we can safely persist these objects. Something like:
///
/// ```
/// // Hopefully not a singleton!
/// let productDAO = storageManager.productDAO
/// // The saveProduct can do the performBlock() on the correct NSManagedObjectContext
/// productDAO.saveProduct(aProduct) {
///     // do something after
/// }
/// ```
///
/// Note that this is only based on my understanding of how child `NSManagedObjectContexts` work
/// and I could be wrong. ¯\_(ツ)_/¯
///
/// ## Site ID
///
/// The `siteID` is automatically determined from the fetched `Note` (`noteID`).
///
final class RetrieveProductReviewFromNoteUseCase {
    typealias CompletionBlock = (Result<ProductReviewFromNoteParcel, Error>) -> Void
    private typealias AbortBlock = (Error) -> Void

    enum ProductReviewFromNoteRetrieveError: Error {
        case notificationNotFound
        case reviewNotFound
        case storageNoLongerAvailable
    }

    private let network: Network

    /// The derived `StorageType` used by the `ProductReviewStore`.
    ///
    /// We should use `weak` because we have to guarantee that we will not do any saving if this
    /// `StorageType` is deallocated, which is part of the `ProductReviewStore` lifecycle.
    ///
    private weak var derivedStorage: StorageType?

    init(network: Network, derivedStorage: StorageType) {
        self.network = network
        self.derivedStorage = derivedStorage
    }

    func retrieve(noteID: Int64, completion: @escaping CompletionBlock) {
        let abort: (Error) -> () = {
            completion(.failure($0))
        }

        fetchNote(noteID: noteID, abort: abort) { [weak self] note in
            self?.fetchProductReview(from: note, abort: abort) { review in
                self?.saveProductReview(review, abort: abort) {
                    self?.fetchProduct(siteID: review.siteID, productID: review.productID, abort: abort, next: { product in
                        let payload = ProductReviewFromNoteParcel(note: note, review: review, product: product)
                        completion(.success(payload))
                    })
                }
            }
        }
    }

    private func fetchNote(noteID: Int64,
                           abort: @escaping AbortBlock,
                           next: @escaping (Note) -> Void) {
        let remote = NotificationsRemote(network: network)

        remote.loadNotes(noteIDs: [noteID]) { result in
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

    private func fetchProductReview(from note: Note,
                                    abort: @escaping AbortBlock,
                                    next: @escaping (ProductReview) -> Void) {
        guard let siteID = note.meta.identifier(forKey: .site),
            let reviewID = note.meta.identifier(forKey: .comment) else {
                return abort(ProductReviewFromNoteRetrieveError.reviewNotFound)
        }

        let remote = ProductReviewsRemote(network: network)

        remote.loadProductReview(for: Int64(siteID), reviewID: Int64(reviewID)) { result in
            switch result {
            case .failure(let error):
                abort(error)
            case .success(let review):
                next(review)
            }
        }
    }

    private func saveProductReview(_ review: ProductReview,
                                   abort: @escaping AbortBlock,
                                   next: @escaping () -> Void) {
        guard let derivedStorage = derivedStorage else {
            return abort(ProductReviewFromNoteRetrieveError.storageNoLongerAvailable)
        }

        derivedStorage.perform {
            let storageReview = derivedStorage.loadProductReview(siteID: review.siteID, reviewID: review.reviewID)
                ?? derivedStorage.insertNewObject(ofType: StorageProductReview.self)
            storageReview.update(with: review)
        }
    }

    private func fetchProduct(siteID: Int64,
                              productID: Int64,
                              abort: @escaping AbortBlock,
                              next: @escaping (Product) -> Void) {
        let remote = ProductsRemote(network: network)

        remote.loadProduct(for: siteID, productID: productID) { result in
            switch result {
            case .failure(let error):
                abort(error)
            case .success(let product):
                next(product)
            }
        }
    }
}


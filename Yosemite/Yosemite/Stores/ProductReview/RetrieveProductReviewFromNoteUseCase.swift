
import Foundation
import Networking
import protocol Storage.StorageType

/// The result from `RetrieveProductReviewFromNoteUseCase`.
///
public struct ProductReviewFromNoteParcel {
    public let note: Note
    public let review: ProductReview
    public let product: Product
}

/// Fetches the `Note`, `ProductReview`, and `Product` in sequence from the API using a `noteID`.
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

    private let notificationsRemote: NotificationsEndpointsProviding
    private let productReviewsRemote: ProductReviewsEndpointsProviding
    private let productsRemote: ProductsEndpointsProviding

    /// The derived `StorageType` used by the `ProductReviewStore`.
    ///
    /// We should use `weak` because we have to guarantee that we will not do any saving if this
    /// `StorageType` is deallocated, which is part of the `ProductReviewStore` lifecycle.
    ///
    private weak var derivedStorage: StorageType?

    /// Create an instance of self.
    ///
    /// - Parameters:
    ///   - derivedStorage: The derived (background) `StorageType` of `ProductReviewStore`.
    init(derivedStorage: StorageType,
         notificationsRemote: NotificationsEndpointsProviding,
         productReviewsRemote: ProductReviewsEndpointsProviding,
         productsRemote: ProductsEndpointsProviding) {
        self.derivedStorage = derivedStorage
        self.notificationsRemote = notificationsRemote
        self.productReviewsRemote = productReviewsRemote
        self.productsRemote = productsRemote
    }

    /// Create an instance of self.
    ///
    /// - Parameters:
    ///   - derivedStorage: The derived (background) `StorageType` of `ProductReviewStore`.
    convenience init(network: Network, derivedStorage: StorageType) {
        self.init(derivedStorage: derivedStorage,
                  notificationsRemote: NotificationsRemote(network: network),
                  productReviewsRemote: ProductReviewsRemote(network: network),
                  productsRemote: ProductsRemote(network: network))
    }

    /// Retrieve the `Note`, `ProductReview`, and `Product` based on the given `noteID`.
    ///
    func retrieve(noteID: Int64, completion: @escaping CompletionBlock) {
        let abort: (Error) -> () = {
            completion(.failure($0))
        }

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

    /// Fetch the Note from the API.
    ///
    private func fetchNote(noteID: Int64,
                           abort: @escaping AbortBlock,
                           next: @escaping (Note) -> Void) {
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

    /// Fetch the ProductReview based on the given Note from the API.
    ///
    private func fetchProductReview(from note: Note,
                                    abort: @escaping AbortBlock,
                                    next: @escaping (ProductReview) -> Void) {
        guard let siteID = note.meta.identifier(forKey: .site),
            let reviewID = note.meta.identifier(forKey: .comment) else {
                return abort(ProductReviewFromNoteRetrieveError.reviewNotFound)
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
        guard let derivedStorage = derivedStorage else {
            return abort(ProductReviewFromNoteRetrieveError.storageNoLongerAvailable)
        }

        derivedStorage.perform {
            let storageReview = derivedStorage.loadProductReview(siteID: review.siteID, reviewID: review.reviewID)
                ?? derivedStorage.insertNewObject(ofType: StorageProductReview.self)
            storageReview.update(with: review)

            DispatchQueue.main.async(execute: next)
        }
    }

    /// Fetch the `Product` from the API.
    ///
    private func fetchProduct(siteID: Int64,
                              productID: Int64,
                              abort: @escaping AbortBlock,
                              next: @escaping (Product) -> Void) {
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

import Foundation
import Storage

struct MockProductReviewActionHandler: MockActionHandler {

    typealias ActionType = ProductReviewAction

    let objectGraph: MockObjectGraph
    let storageManager: StorageManagerType

    func handle(action: ActionType) {
        switch action {
            case .synchronizeProductReviews(let siteID, _, _, _, _, let onCompletion):
                synchronizeProductReviews(siteId: siteID, onCompletion: onCompletion)

            default: unimplementedAction(action: action)
        }
    }

    func synchronizeProductReviews(siteId: Int64, onCompletion: @escaping (Result<[ProductReview], Error>) -> Void) {
        let reviews = objectGraph.reviews(forSiteId: siteId)

        // Deletes previous product reviews before saving new ones to avoid duplicate reviews after multiple runs.
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: StorageProductReview.self)
        storage.saveIfNeeded()

        save(mocks: reviews, as: StorageProductReview.self) { error in
            if let error = error {
                onCompletion(.failure(error))
            } else {
                onCompletion(.success(reviews))
            }
        }
    }
}

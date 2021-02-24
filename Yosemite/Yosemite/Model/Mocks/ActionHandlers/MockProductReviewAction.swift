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

    func synchronizeProductReviews(siteId: Int64, onCompletion: @escaping (Error?) -> ()) {
        let reviews = objectGraph.reviews(forSiteId: siteId)
        save(mocks: reviews, as: StorageProductReview.self, onCompletion: onCompletion)
    }
}

import Foundation
import Storage


// MARK: - Yosemite.ProductReview: ReadOnlyType
//
extension Yosemite.ProductReview: ReadOnlyType {

    /// Indicates if the receiver is a representation of a specified Storage.Entity instance.
    ///
    public func isReadOnlyRepresentation(of storageEntity: Any) -> Bool {
        guard let storageProductReview = storageEntity as? Storage.ProductReview else {
            return false
        }

        return storageProductReview.reviewID == reviewID
    }
}

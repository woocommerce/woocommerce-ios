import Foundation
import Networking

/// ProductReviewAction: Defines all of the Actions supported by the ProductReviewStore.
///
public enum ProductReviewAction: Action {

    /// Synchronizes the ProductReviews matching the specified criteria.
    ///
    case synchronizeProductReviews(siteID: Int64,
        pageNumber: Int,
        pageSize: Int,
        products: [Int64]? = nil,
        status: ProductReviewStatus? = nil,
        onCompletion: (Error?) -> Void)

    /// Retrieves the specified ProductReview.
    ///
    case retrieveProductReview(siteID: Int64, reviewID: Int64, onCompletion: (ProductReview?, Error?) -> Void)

    /// Retrieves the `Note`, `ProductReview`, and `Product` in sequence.
    ///
    /// Only the `ProductReview` is stored in the database. Please see
    /// `RetrieveProductReviewFromNoteUseCase` for the reason why.
    ///
    case retrieveProductReviewFromNote(noteID: Int64,
                                       onCompletion: (Result<ProductReviewFromNoteParcel, Error>) -> Void)

    /// Updates the approval status of a review (approved/on hold).
    /// The completion closure will return the updated review status or error (if any).
    ///
    case updateApprovalStatus(siteID: Int64, reviewID: Int64, isApproved: Bool, onCompletion: (ProductReviewStatus?, Error?) -> Void)

    /// Updates the trash status of a review (trash/untrash).
    /// The completion closure will return the updated review status or error (if any).
    ///
    case updateTrashStatus(siteID: Int64, reviewID: Int64, isTrashed: Bool, onCompletion: (ProductReviewStatus?, Error?) -> Void)

    /// Updates the spam/unspam status of a review (trash/untrash).
    /// The completion closure will return the updated review status or error (if any).
    ///
    case updateSpamStatus(siteID: Int64, reviewID: Int64, isSpam: Bool, onCompletion: (ProductReviewStatus?, Error?) -> Void)

    /// Deletes all of the cached product reviews.
    ///
    case resetStoredProductReviews(onCompletion: () -> Void)
}

import Foundation
import Storage


// MARK: - Storage.ProductReview: ReadOnlyConvertible
//
extension Storage.ProductReview: ReadOnlyConvertible {

    /// Updates the Storage.ProductReview with the ReadOnly.
    ///
    public func update(with review: Yosemite.ProductReview) {
        siteID              = review.siteID
        reviewID            = review.reviewID
        productID           = review.productID
        dateCreated         = review.dateCreated
        statusKey           = review.statusKey
        reviewer            = review.reviewer
        reviewerEmail       = review.reviewerEmail
        reviewerAvatarURL   = review.reviewerAvatarURL
        self.review         = review.review
        rating              = Int64(review.rating)
        verified            = review.verified
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.ProductReview {
        return ProductReview(siteID: siteID,
                             reviewID: reviewID,
                             productID: productID,
                             dateCreated: dateCreated ?? Date(),
                             statusKey: statusKey ?? "",
                             reviewer: reviewer ?? "" ,
                             reviewerEmail: reviewerEmail ?? "",
                             reviewerAvatarURL: reviewerAvatarURL,
                             review: review ?? "",
                             rating: Int(rating),
                             verified: verified)
    }
}

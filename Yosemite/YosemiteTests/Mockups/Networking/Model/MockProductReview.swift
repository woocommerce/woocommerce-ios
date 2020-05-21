
import Foundation

import Networking

/// Provides builders for `Note` to use as test data.
///
struct MockProductReview {
    func make(siteID: Int64, reviewID: Int64, productID: Int64) -> ProductReview {
        ProductReview(siteID: siteID,
                      reviewID: reviewID,
                      productID: productID,
                      dateCreated: Date(),
                      statusKey: "",
                      reviewer: "",
                      reviewerEmail: "",
                      reviewerAvatarURL: nil,
                      review: "",
                      rating: 0,
                      verified: false)
    }
}

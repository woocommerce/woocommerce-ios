import Foundation
@testable import Networking

final class MockReviews {
    let siteID          = 123
    let reviewID        = 1234
    let productID       = 12345
    let dateCreated     = Date()
    let statusKey       = "hold"
    let reviewer        = "A Human"
    let reviewerEmail   = "somewhere@on.the.internet.com"
    let reviewText      = "<p>A remarkable artifact</p>"
    let rating          = 4
    let verified        = true

    func review() -> Networking.ProductReview {
        return ProductReview(siteID: siteID,
                             reviewID: reviewID,
                             productID: productID,
                             dateCreated: dateCreated,
                             statusKey: statusKey,
                             reviewer: reviewer,
                             reviewerEmail: reviewerEmail,
                             review: reviewText,
                             rating: rating,
                             verified: verified)
    }
}

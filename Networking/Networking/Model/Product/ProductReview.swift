import Foundation

/// Represents a ProductReview Entity.
///
public struct ProductReview: Decodable {
    public let siteID: Int64
    public let reviewID: Int64
    public let productID: Int64

    public let dateCreated: Date        // gmt

    public let statusKey: String

    public let reviewer: String
    public let reviewerEmail: String
    public let reviewerAvatarURL: String

    public let review: String
    public let rating: Int

    public let verified: Bool

    public var status: ProductReviewStatus {
        return ProductReviewStatus(rawValue: statusKey)
    }

    /// ProductReview struct initializer.
    ///
    public init(siteID: Int64,
                reviewID: Int64,
                productID: Int64,
                dateCreated: Date,
                statusKey: String,
                reviewer: String,
                reviewerEmail: String,
                reviewerAvatarURL: String,
                review: String,
                rating: Int,
                verified: Bool) {
        self.siteID = siteID
        self.reviewID = reviewID
        self.productID = productID
        self.dateCreated = dateCreated
        self.statusKey = statusKey
        self.reviewer = reviewer
        self.reviewerEmail = reviewerEmail
        self.reviewerAvatarURL = reviewerAvatarURL
        self.review = review
        self.rating = rating
        self.verified = verified
    }

    /// The public initializer for ProductReview.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw ProductReviewDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let reviewID = try container.decode(Int64.self, forKey: .reviewID)
        let productID = try container.decode(Int64.self, forKey: .productID)
        let dateCreated = try container.decodeIfPresent(Date.self, forKey: .dateCreated) ?? Date()
        let statusKey = try container.decode(String.self, forKey: .status)
        let reviewer = try container.decode(String.self, forKey: .reviewer)
        let reviewerEmail = try container.decode(String.self, forKey: .reviewerEmail)
        let avatarURLs = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .avatarURLs)
        let reviewerAvatarURL = try avatarURLs.decode(String.self, forKey: .avatar96)
        let review = try container.decode(String.self, forKey: .review)
        let rating = try container.decode(Int.self, forKey: .rating)
        let verified = try container.decode(Bool.self, forKey: .verified)

        self.init(siteID: siteID,
                  reviewID: reviewID,
                  productID: productID,
                  dateCreated: dateCreated,
                  statusKey: statusKey,
                  reviewer: reviewer,
                  reviewerEmail: reviewerEmail,
                  reviewerAvatarURL: reviewerAvatarURL,
                  review: review,
                  rating: rating,
                  verified: verified)
    }
}


/// Defines all of the ProductReview CodingKeys
///
private extension ProductReview {

    enum CodingKeys: String, CodingKey {
        case reviewID       = "id"
        case productID      = "product_id"
        case dateCreated    = "date_created_gmt"
        case status         = "status"
        case reviewer       = "reviewer"
        case reviewerEmail  = "reviewer_email"
        case avatarURLs     = "reviewer_avatar_urls"
        /// We are ignoring all avatars except the one marked as 96
        /// to avoid adding an unecessary intermediate object
        case avatar96       = "96"
        case review         = "review"
        case rating         = "rating"
        case verified       = "verified"
    }
}


// MARK: - Equatable Conformance
//
extension ProductReview: Equatable {
    public static func == (lhs: ProductReview, rhs: ProductReview) -> Bool {
        return lhs.siteID == rhs.siteID &&
            lhs.reviewID == rhs.reviewID &&
            lhs.productID == rhs.productID
    }
}


// MARK: - Decoding Errors
//
enum ProductReviewDecodingError: Error {
    case missingSiteID
}

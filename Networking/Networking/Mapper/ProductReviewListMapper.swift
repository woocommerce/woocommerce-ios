import Foundation

/// Mapper: Product Reviews List
///
struct ProductReviewListMapper: Mapper {
    /// Site Identifier associated to the product reviews that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [Product].
    ///
    func map(response: Data) throws -> [ProductReview] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductReviewListEnvelope.self, from: response).productReviews
        } else {
            return try decoder.decode([ProductReview].self, from: response)
        }
    }
}


/// ProductReviewListEnvelope Disposable Entity:
/// `Load All Products Reviews` endpoint returns the updated products document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductReviewListEnvelope: Decodable {
    let productReviews: [ProductReview]

    private enum CodingKeys: String, CodingKey {
        case productReviews = "data"
    }
}

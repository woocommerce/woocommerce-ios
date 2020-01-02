import Foundation


/// Mapper: ProductReview
///
struct ProductReviewMapper: Mapper {

    /// Site Identifier associated to the product review that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into ProductReview.
    ///
    func map(response: Data) throws -> ProductReview {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductReviewEnvelope.self, from: response).productReview
    }
}


/// ProductReviewEnvelope Disposable Entity
///
/// `Load Product Review` endpoint returns the requested product document in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ProductReviewEnvelope: Decodable {
    let productReview: ProductReview

    private enum CodingKeys: String, CodingKey {
        case productReview = "data"
    }
}

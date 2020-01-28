import Foundation


/// Mapper: Product
///
struct ProductMapper: Mapper {

    /// Site Identifier associated to the product that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into Product.
    ///
    func map(response: Data) throws -> Product {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductEnvelope.self, from: response).product
    }
}


/// ProductEnvelope Disposable Entity
///
/// `Load Product` endpoint returns the requested product document in the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct ProductEnvelope: Decodable {
    let product: Product

    private enum CodingKeys: String, CodingKey {
        case product = "data"
    }
}

import Foundation


/// Mapper: Product
///
public struct ProductMapper: Mapper {

    /// Site Identifier associated to the product that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Endpoints.
    ///
    public let siteID: Int64

    /// Public initializer
    public init(siteID: Int64) {
        self.siteID = siteID
    }

    /// (Attempts) to convert a dictionary into Product.
    ///
    public func map(response: Data) throws -> Product {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductEnvelope.self, from: response).product
        } else {
            return try decoder.decode(Product.self, from: response)
        }
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

import Foundation

/// Mapper: ProductAttributeTerm
///
struct ProductAttributeTermMapper: Mapper {

    /// Site Identifier associated to the `ProductAttributeTerm`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the `ProductAttributeTerm` Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `ProductAttributeTerm`.
    ///
    func map(response: Data) throws -> ProductAttributeTerm {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductAttributeTermEnvelope.self, from: response).productAttributeTerm
    }
}


/// ProductAttributeTermEnvelope Disposable Entity:
/// `Load ProductProductAttributeTerm` endpoint returns the updated products document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductAttributeTermEnvelope: Decodable {
    let productAttributeTerm: ProductAttributeTerm

    private enum CodingKeys: String, CodingKey {
        case productAttributeTerm = "data"
    }
}

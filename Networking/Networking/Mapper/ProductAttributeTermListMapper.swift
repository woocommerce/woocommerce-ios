import Foundation

/// Mapper: ProductAttributeTerm List
///
struct ProductAttributeTermListMapper: Mapper {
    /// Site Identifier associated to the `ProductAttributeTermList`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductAttributeTerm Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into `[ProductAttributeTerm]`.
    ///
    func map(response: Data) throws -> [ProductAttributeTerm] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductAttributeTermListEnvelope.self, from: response).productAttributeTerms
    }
}

/// ProductAttributeTermListEnvelope Disposable Entity:
/// `Load All ProductsAttributeTerm` endpoint returns the updated products document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductAttributeTermListEnvelope: Decodable {
    let productAttributeTerms: [ProductAttributeTerm]

    private enum CodingKeys: String, CodingKey {
        case productAttributeTerms = "data"
    }
}

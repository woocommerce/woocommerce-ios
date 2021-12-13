import Foundation


/// Mapper: ProductAttribute
///
struct ProductAttributeMapper: Mapper {

    /// Site Identifier associated to the `productAttribute`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductAttribute Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into ProductAttribute.
    ///
    func map(response: Data) throws -> ProductAttribute {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductAttributeEnvelope.self, from: response).productAttribute
    }
}


/// ProductAttributeEnvelope Disposable Entity:
/// `Load Product Attribute` endpoint returns the updated products document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductAttributeEnvelope: Decodable {
    let productAttribute: ProductAttribute

    private enum CodingKeys: String, CodingKey {
        case productAttribute = "data"
    }
}

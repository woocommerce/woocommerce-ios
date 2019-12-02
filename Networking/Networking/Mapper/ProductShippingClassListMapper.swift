import Foundation

/// Mapper: ProductShippingClass List
///
struct ProductShippingClassListMapper: Mapper {
    /// Site Identifier associated to the product variation that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Variation Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into [ProductShippingClass].
    ///
    func map(response: Data) throws -> [ProductShippingClass] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductShippingClassListEnvelope.self, from: response).data
    }
}


/// ProductShippingClassListEnvelope Disposable Entity
///
/// `Load All ProductShippingClass` endpoint returns the requested data in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ProductShippingClassListEnvelope: Decodable {
    let data: [ProductShippingClass]

    private enum CodingKeys: String, CodingKey {
        case data = "data"
    }
}

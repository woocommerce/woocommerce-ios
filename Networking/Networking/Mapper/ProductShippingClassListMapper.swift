import Foundation

/// Mapper: ProductShippingClass List
///
struct ProductShippingClassListMapper: Mapper {
    /// Site Identifier associated to the product variation that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Variation Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into ProductVariation.
    ///
    func map(response: Data) throws -> [ProductShippingClass] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID,
        ]

        return try decoder.decode(ProductShippingClassesEnvelope.self, from: response).productShippingClasses
    }
}

/// ProductShippingClassesEnvelope Disposable Entity
///
/// `Load Product Shipping Classes` endpoint returns the requested objects in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ProductShippingClassesEnvelope: Decodable {
    let productShippingClasses: [ProductShippingClass]

    private enum CodingKeys: String, CodingKey {
        case productShippingClasses = "data"
    }
}

import Foundation

/// Mapper: ProductShippingClass
///
struct ProductShippingClassMapper: Mapper {
    /// Site Identifier associated to the ProductShippingClass that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductShippingClass Endpoints.
    ///
    let siteID: Int64

    /// (Attempts) to convert a dictionary into ProductShippingClass.
    ///
    func map(response: Data) throws -> ProductShippingClass {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductShippingClassEnvelope.self, from: response).productShippingClass
    }
}


/// ProductShippingClassEnvelope Disposable Entity
///
/// `Load ProductShippingClass` endpoint returns the requested data in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ProductShippingClassEnvelope: Decodable {
    let productShippingClass: ProductShippingClass

    private enum CodingKeys: String, CodingKey {
        case productShippingClass = "data"
    }
}

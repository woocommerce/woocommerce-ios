import Foundation

/// Mapper: ProductVariation
///
struct ProductVariationMapper: Mapper {
    /// Site Identifier associated to the product variation that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the Product Variation Endpoints.
    ///
    let siteID: Int64

    /// Product Identifier associated to the product variation that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because ProductID is not returned in any of the Product Variation Endpoints.
    ///
    let productID: Int64

    /// (Attempts) to convert a dictionary into ProductVariation.
    ///
    func map(response: Data) throws -> ProductVariation {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .productID: productID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductVariationEnvelope.self, from: response).productVariation
        } else {
            return try decoder.decode(ProductVariation.self, from: response)
        }
    }
}

/// ProductVariationEnvelope Disposable Entity
///
/// `ProductVariation` endpoint returns the requested product variation document in the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct ProductVariationEnvelope: Decodable {
    let productVariation: ProductVariation

    private enum CodingKeys: String, CodingKey {
        case productVariation = "data"
    }
}

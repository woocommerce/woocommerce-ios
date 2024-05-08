#if os(iOS)

import Foundation


/// Mapper: ProductVariation List
///
struct ProductVariationListMapper: Mapper {
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
    func map(response: Data) throws -> [ProductVariation] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .productID: productID
        ]

        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductVariationsEnvelope.self, from: response).productVariations
        } else {
            return try decoder.decode([ProductVariation].self, from: response)
        }
    }
}

/// ProductVariationsEnvelope Disposable Entity
///
/// `Load Product Variations` endpoint returns the requested objects in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ProductVariationsEnvelope: Decodable {
    let productVariations: [ProductVariation]

    private enum CodingKeys: String, CodingKey {
        case productVariations = "data"
    }
}

#endif

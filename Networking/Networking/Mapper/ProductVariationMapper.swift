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
        return try decoder.decode(ProductVariationEnvelope.self, from: response).productVariation
    }
}

/// Mapper: ProductVariations
///
struct ProductVariationsMapper: Mapper {
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

    /// (Attempts) to convert a dictionary into ProductVariations.
    ///
    func map(response: Data) throws -> [ProductVariation] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .productID: productID
        ]
        return try decoder.decode(ProductVariationsEnvelope.self, from: response).updatedProductVariations
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

/// ProductVariationsEnvelope Disposable Entity
///
/// `Variations/batch` endpoint returns the requested update product variations document in a `update` key, nested in a `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductVariationsEnvelope: Decodable {
    let updatedProductVariations: [ProductVariation]

    private enum CodingKeys: String, CodingKey {
        case update = "update"
    }

    private enum TopLevelCodingKeys: String, CodingKey {
        case data = "data"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: TopLevelCodingKeys.self)

        let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        updatedProductVariations = try nestedContainer.decode([ProductVariation].self, forKey: .update)
    }
}

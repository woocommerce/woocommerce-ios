import Foundation

/// Mapper: ProductVariationsBulkCreateMapper
///
struct ProductVariationsBulkCreateMapper: Mapper {
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
        return try decoder.decode(ProductVariationsEnvelope.self, from: response).createdProductVariations
    }
}

/// ProductVariationsEnvelope Disposable Entity
///
/// `Variations/batch` endpoint returns the requested create product variations document in a `create` key, nested in a `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductVariationsEnvelope: Decodable {
    let createdProductVariations: [ProductVariation]

    private enum CodingKeys: String, CodingKey {
        case data
        case create
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            let nestedContainer = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
            createdProductVariations = try nestedContainer.decode([ProductVariation].self, forKey: .create)
        } catch {
            createdProductVariations = try container.decode([ProductVariation].self, forKey: .create)
        }
    }
}

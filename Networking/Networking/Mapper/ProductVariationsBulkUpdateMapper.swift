#if os(iOS)

import Foundation

/// Mapper: ProductVariationsBulkUpdateMapper
///
struct ProductVariationsBulkUpdateMapper: Mapper {
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
        if hasDataEnvelope(in: response) {
            return try decoder.decode(ProductVariationsContainerEnvelope.self, from: response).data.updatedProductVariations
        } else {
            return try decoder.decode(ProductVariationsContainer.self, from: response).updatedProductVariations
        }
    }
}

/// ProductVariationsEnvelope Disposable Entity
///
/// `Variations/batch` endpoint returns the requested update product variations document in a `update` key, nested in a `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductVariationsContainerEnvelope: Decodable {
    let data: ProductVariationsContainer

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

private struct ProductVariationsContainer: Decodable {
    let updatedProductVariations: [ProductVariation]

    private enum CodingKeys: String, CodingKey {
        case updatedProductVariations = "update"
    }
}

#endif

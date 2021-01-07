import Foundation


/// Mapper: ProductVariationInBatchList
///
struct ProductVariationInBatchListMapper: Mapper {
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

    /// (Attempts) to convert a dictionary into a list of ProductVariationInBatch. The mapping returns Product variations created, updated, deleted.
    ///
    func map(response: Data) throws -> ProductVariationInBatch {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .productID: productID
        ]
        return try decoder.decode(ProductVariationInBatchEnvelope.self, from: response).productVariationsInBatch
    }
}

/// ProductVariationInBatchEnvelope Disposable Entity
///
/// `Create/Update/Delete Product Variations in batch` endpoint returns the requested objects in the `data` key. This entity
/// allows us to parse all the things with JSONDecoder.
///
private struct ProductVariationInBatchEnvelope: Decodable {
    let productVariationsInBatch: ProductVariationInBatch

    private enum CodingKeys: String, CodingKey {
        case productVariationsInBatch = "data"
    }
}

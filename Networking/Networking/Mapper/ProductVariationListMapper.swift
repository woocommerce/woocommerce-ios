import Foundation


/// Mapper: ProductVariation List
///
struct ProductVariationListMapper: Mapper {

    /// Site Identifier associated to the product variations that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductVariation Endpoints.
    ///
    let siteID: Int

    /// Product Identifier associated to the product that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because ProductID is not returned in any of the ProductVariation Endpoints.
    ///
    let productID: Int

    /// (Attempts) to convert a dictionary into [Product].
    ///
    func map(response: Data) throws -> [ProductVariation] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .formatted(DateFormatter.Defaults.dateTimeFormatter)
        decoder.userInfo = [
            .siteID: siteID,
            .productID: productID
        ]

        return try decoder.decode(ProductVariationListEnvelope.self, from: response).productVariations
    }
}


/// ProductVariationListEnvelope Disposable Entity
///
/// `Load All ProductVariations` endpoint returns the requested product variations in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductVariationListEnvelope: Decodable {
    let productVariations: [ProductVariation]

    private enum CodingKeys: String, CodingKey {
        case productVariations = "data"
    }
}

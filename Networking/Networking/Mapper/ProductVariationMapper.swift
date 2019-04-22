import Foundation


/// Mapper: ProductVariation
///
struct ProductVariationMapper: Mapper {

    /// Site Identifier associated to the product variation that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductVariation Endpoints.
    ///
    let siteID: Int

    /// Product Identifier associated to the product variation that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because ProductID is not returned in any of the ProductVariation Endpoints.
    ///
    let productID: Int

    /// (Attempts) to convert a dictionary into Product.
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


/// ProductVariationEnvelope Disposable Entity
///
/// `Load ProductVariation` endpoint returns the requested product variation document in the `data` key. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct ProductVariationEnvelope: Decodable {
    let productVariation: ProductVariation

    private enum CodingKeys: String, CodingKey {
        case productVariation = "data"
    }
}

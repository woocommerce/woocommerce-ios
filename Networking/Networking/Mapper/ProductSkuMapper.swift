import Foundation


/// Mapper: Product Sku String
///
struct ProductSkuMapper: Mapper {

    /// (Attempts) to convert an instance of Data into a Product Sku string
    ///
    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()

        return try decoder.decode(ProductSkuEnvelope.self, from: response).productsSkus["sku"] ?? ""
    }
}


/// ProductSkuEnvelope Disposable Entity:
/// `Products` endpoint returns if a sku exists. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct ProductSkuEnvelope: Decodable {
    let productsSkus: [String: String]

    private enum CodingKeys: String, CodingKey {
        case productsSkus = "data"
    }
}

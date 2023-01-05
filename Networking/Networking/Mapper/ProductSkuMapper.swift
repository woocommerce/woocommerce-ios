import Foundation


/// Mapper: Product Sku String
///
struct ProductSkuMapper: Mapper {

    /// (Attempts) to convert an instance of Data into a Product Sku string
    ///
    func map(response: Data) throws -> String {
        let decoder = JSONDecoder()

        do {
            return try decoder.decode(ProductSkuEnvelope.self, from: response).productsSkus.first?[Constants.skuKey] ?? ""
        } catch {
            return try decoder.decode(ProductSkuEnvelope.SkuType.self, from: response).first?[Constants.skuKey] ?? ""
        }
    }
}

// MARK: Constants
//
private extension ProductSkuMapper {
    enum Constants {
        static let skuKey = "sku"
    }
}

/// ProductSkuEnvelope Disposable Entity:
/// `Products` endpoint returns if a sku exists. This entity
/// allows us to do parse all the things with JSONDecoder.
///
private struct ProductSkuEnvelope: Decodable {
    typealias SkuType = [[String: String]]

    let productsSkus: SkuType

    private enum CodingKeys: String, CodingKey {
        case productsSkus = "data"
    }
}

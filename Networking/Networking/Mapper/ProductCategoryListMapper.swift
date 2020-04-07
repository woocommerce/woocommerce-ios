import Foundation

/// Mapper: ProductCategory List
///
struct ProductCategoryListMapper: Mapper {

    /// (Attempts) to convert a dictionary into [ProductCategory].
    ///
    func map(response: Data) throws -> [ProductCategory] {
        let decoder = JSONDecoder()
        return try decoder.decode(ProductCategoryListEnvelope.self, from: response).productCategories
    }
}


/// ProductCategoryListEnvelope Disposable Entity:
/// `Load All Products Categories` endpoint returns the updated products document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductCategoryListEnvelope: Decodable {
    let productCategories: [ProductCategory]

    private enum CodingKeys: String, CodingKey {
        case productCategories = "data"
    }
}

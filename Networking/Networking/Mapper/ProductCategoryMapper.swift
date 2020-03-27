import Foundation

/// Mapper: ProductCateogy
///
struct ProductCategoryMapper: Mapper {

    /// (Attempts) to convert a dictionary into a ProductCategory.
    ///
    func map(response: Data) throws -> ProductCategory {
        let decoder = JSONDecoder()
        return try decoder.decode(ProductCategoryEnvelope.self, from: response).productCategory
    }
}


/// ProductCategoryEnvelope Disposable Entity
///
/// `Load Product Categories` endpoint returns the requested product document in the `data` key. This entity
/// allows us to parse it with JSONDecoder.
///
private struct ProductCategoryEnvelope: Decodable {
    let productCategory: ProductCategory

    private enum CodingKeys: String, CodingKey {
        case productCategory = "data"
    }
}

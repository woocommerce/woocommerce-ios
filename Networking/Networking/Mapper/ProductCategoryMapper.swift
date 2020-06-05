import Foundation


/// Mapper: ProductCategory
///
struct ProductCategoryMapper: Mapper {

    /// Site Identifier associated to the `ProductCategory`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductCategory Endpoints.
    ///
    let siteID: Int64


    /// (Attempts) to convert a dictionary into ProductCategory.
    ///
    func map(response: Data) throws -> ProductCategory {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        return try decoder.decode(ProductCategoryEnvelope.self, from: response).productCategory
    }
}


/// ProductCategoryEnvelope Disposable Entity:
/// `Load Product Category` endpoint returns the updated products document in the `data` key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductCategoryEnvelope: Decodable {
    let productCategory: ProductCategory

    private enum CodingKeys: String, CodingKey {
        case productCategory = "data"
    }
}

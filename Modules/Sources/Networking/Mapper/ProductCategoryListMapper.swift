import Foundation

/// Mapper: ProductCategory List
///
struct ProductCategoryListMapper: Mapper {
    /// Site Identifier associated to the `ProductCategories`s that will be parsed.
    ///
    /// We're injecting this field via `JSONDecoder.userInfo` because SiteID is not returned in any of the ProductCategory Endpoints.
    ///
    let siteID: Int64

    let responseType: ResponseType

    /// (Attempts) to convert a dictionary into [ProductCategory].
    ///
    func map(response: Data) throws -> [ProductCategory] {
        let decoder = JSONDecoder()
        decoder.userInfo = [
            .siteID: siteID
        ]

        let hasDataEnvelope = hasDataEnvelope(in: response)

        switch responseType {
        case .load:
            if hasDataEnvelope {
                return try decoder.decode(ProductCategoryListEnvelope.self, from: response).productCategories
            } else {
                return try decoder.decode([ProductCategory].self, from: response)
            }
        case .create:
            let categories: [ProductCategoryFromBatchCreation] = try {
                if hasDataEnvelope {
                    return try decoder.decode(ProductCategoryListBatchCreateEnvelope.self, from: response).data.categories
                } else {
                    return try decoder.decode(ProductCategoryListBatchCreateContainer.self, from: response).categories
                }
            }()
            return categories
                .filter { $0.error == nil }
                .compactMap { (categoryCreated) -> ProductCategory? in
                    if let name = categoryCreated.name, let slug = categoryCreated.slug {
                        return ProductCategory(categoryID: categoryCreated.categoryID,
                                               siteID: categoryCreated.siteID,
                                               parentID: categoryCreated.parentID,
                                               name: name,
                                               slug: slug)
                    }
                    return nil
                }
        }
    }

    enum ResponseType {
      case load
      case create
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

/// ProductCategoryListBatchCreateEnvelope Disposable Entity:
/// `Batch Create Products Categories` endpoint returns the products tags under the `data` key, nested under `create`  key.
/// This entity allows us to do parse all the things with JSONDecoder.
///
private struct ProductCategoryListBatchCreateEnvelope: Decodable {
    let data: ProductCategoryListBatchCreateContainer

    private enum CodingKeys: String, CodingKey {
        case data
    }
}

private struct ProductCategoryListBatchCreateContainer: Decodable {
    let categories: [ProductCategoryFromBatchCreation]

    private enum CodingKeys: String, CodingKey {
        case categories = "create"
    }
}

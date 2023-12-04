import Foundation

public protocol ProductCategoriesRemoteProtocol {
    func loadAllProductCategories(for siteID: Int64,
                                  pageNumber: Int,
                                  pageSize: Int,
                                  completion: @escaping ([ProductCategory]?, Error?) -> Void)

    func loadProductCategory(with categoryID: Int64,
                             siteID: Int64,
                             completion: @escaping (Result<ProductCategory, Error>) -> Void) -> Void

    func createProductCategory(for siteID: Int64,
                               name: String,
                               parentID: Int64?,
                               completion: @escaping (Result<ProductCategory, Error>) -> Void)

    func createProductCategories(for siteID: Int64,
                                 names: [String],
                                 parentID: Int64?,
                                 completion: @escaping (Result<[ProductCategory], Error>) -> Void)

    func updateProductCategory(_ category: ProductCategory) async throws -> ProductCategory

    func deleteProductCategory(for siteID: Int64, categoryID: Int64) async throws
}

/// Product Categories: Remote Endpoints
///
public final class ProductCategoriesRemote: Remote, ProductCategoriesRemoteProtocol {

    // MARK: - Product Categories

    /// Retrieves all of the `ProductCategory` available. We rely on the endpoint
    /// defaults for `context`, ` sorting` and `orderby`: `date_gmt` and `asc`
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products categories.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of categories to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProductCategories(for siteID: Int64,
                                         pageNumber: Int = Default.pageNumber,
                                         pageSize: Int = Default.pageSize,
                                         completion: @escaping ([ProductCategory]?, Error?) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize)
        ]

        let path = Path.categories
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductCategoryListMapper(siteID: siteID, responseType: .load)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Loads a remote `ProductCategory`
    ///
    /// - Parameters:
    ///     - categoryID: Category Id of the requested product category.
    ///     - siteID: Site from which we'll fetch the remote product category.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProductCategory(with categoryID: Int64,
                                    siteID: Int64,
                                    completion: @escaping (Result<ProductCategory, Error>) -> Void) -> Void {
        let path = Path.categories + "/\(categoryID)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     availableAsRESTRequest: true)
        let mapper = ProductCategoryMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Create a new `ProductCategory`.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll add a new product categories.
    ///     - name: Category name.
    ///     - parentID: The ID for the parent of the category.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createProductCategory(for siteID: Int64,
                                      name: String,
                                      parentID: Int64?,
                                      completion: @escaping (Result<ProductCategory, Error>) -> Void) {
        var parameters = [
            ParameterKey.name: name
        ]

        if let parentID = parentID {
            parameters[ParameterKey.parent] = String(parentID)
        }

        let path = Path.categories
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductCategoryMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }


    /// Create new multiple `ProductCategory` entities.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll add new product categories.
    ///     - names: Array of category names.
    ///     - parentID: The ID for the parent of the categories.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createProductCategories(for siteID: Int64,
                                        names: [String],
                                        parentID: Int64?,
                                        completion: @escaping (Result<[ProductCategory], Error>) -> Void) {

        let parameters = [
            ParameterKey.create: names.map { name in
                var json = [ParameterKey.name: name]
                if let parentID {
                    json[ParameterKey.parent] = String(parentID)
                }
                return json
            }
        ]

        let path = Path.categoriesBatch
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductCategoryListMapper(siteID: siteID, responseType: .create)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Updates an existing `ProductCategory`.
    ///
    /// - Parameter category: Details to be updated for a category.
    ///
    public func updateProductCategory(_ category: ProductCategory) async throws -> ProductCategory {
        let parameters: [String: Any] = [
            ParameterKey.name: category.name,
            ParameterKey.parent: category.parentID
        ]
        let categoryID = category.categoryID
        let siteID = category.siteID
        let path = Path.categories + "/\(categoryID)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .post,
                                     siteID: siteID,
                                     path: path,
                                     parameters: parameters,
                                     availableAsRESTRequest: true)
        let mapper = ProductCategoryMapper(siteID: siteID)
        return try await enqueue(request, mapper: mapper)
    }

    /// Deletes an existing `ProductCategory`.
    ///
    /// - Parameters:
    ///   - siteID: Site that the category belongs to.
    ///   - categoryID: ID of the category to be deleted.
    ///
    public func deleteProductCategory(for siteID: Int64, categoryID: Int64) async throws {
        let path = "\(Path.categories)/\(categoryID)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .delete,
                                     siteID: siteID,
                                     path: path,
                                     parameters: ["force": "true"],
                                     availableAsRESTRequest: true)
        try await enqueue(request)
    }
}


// MARK: - Constants
//
public extension ProductCategoriesRemote {
    enum Default {
        public static let pageSize: Int = 25
        public static let pageNumber: Int = 1
    }

    private enum Path {
        static let categories = "products/categories"
        static let categoriesBatch = "products/categories/batch"
    }

    private enum ParameterKey {
        static let page: String = "page"
        static let perPage: String = "per_page"
        static let name: String = "name"
        static let parent: String = "parent"
        static let create: String = "create"
    }
}

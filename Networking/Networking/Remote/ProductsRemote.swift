import Foundation
import Alamofire


/// Product: Remote Endpoints
///
public class ProductsRemote: Remote {

    // MARK: - Products

    /// Retrieves all of the `Products` available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote products.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Orders to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProducts(for siteID: Int,
                                context: String? = nil,
                                pageNumber: Int = Defaults.pageNumber,
                                pageSize: Int = Defaults.pageSize,
                                completion: @escaping ([Product]?, Error?) -> Void) {
        let parameters = [
            ParameterKeys.page: String(pageNumber),
            ParameterKeys.perPage: String(pageSize),
            ParameterKeys.contextKey: context ?? Defaults.context
        ]

        let path = Paths.products
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductListMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a specific `Product`
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the Product.
    ///     - productID: Identifier of the Product.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProduct(for siteID: Int, productID: Int, completion: @escaping (Product?, Error?) -> Void) {
        let path = "\(Paths.products)/\(productID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ProductMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    // MARK: - Product Variations

    /// Retrieves all of the `ProductVariation`s available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote product variations.
    ///     - productID: Product for which we'll fetch remote variations.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Orders to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProductVariations(for siteID: Int,
                                         productID: Int,
                                         context: String? = nil,
                                         pageNumber: Int = Defaults.pageNumber,
                                         pageSize: Int = Defaults.pageSize,
                                         completion: @escaping ([ProductVariation]?, Error?) -> Void) {
        let parameters = [
            ParameterKeys.page: String(pageNumber),
            ParameterKeys.perPage: String(pageSize),
            ParameterKeys.contextKey: context ?? Defaults.context
        ]

        let path = "\(Paths.products)/" + String(productID) + "/" + "\(Paths.variations)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductVariationListMapper(siteID: siteID, productID: productID)

        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a specific `ProductVariation`
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the remote product variation.
    ///     - productID: Product for which we'll fetch the remote variation.
    ///     - variationID: Identifier of the Product Variation.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProductVariation(for siteID: Int, productID: Int, variationID: Int, completion: @escaping (ProductVariation?, Error?) -> Void) {
        let path = "\(Paths.products)/" + String(productID) + "/" + "\(Paths.variations)/" + String(variationID)
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ProductVariationMapper(siteID: siteID, productID: productID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
public extension ProductsRemote {
    public enum Defaults {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = 1
        public static let context: String = "view"
    }

    private enum Paths {
        static let products   = "products"
        static let variations = "variations"
    }

    private enum ParameterKeys {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
    }
}

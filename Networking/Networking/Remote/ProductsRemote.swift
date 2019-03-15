import Foundation
import Alamofire


/// Product: Remote Endpoints
///
public class ProductsRemote: Remote {
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

        let path = Constants.productsPath
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = ProductListMapper(siteID: siteID)

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

    private enum Constants {
        static let productsPath = "products"
    }

    private enum ParameterKeys {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
    }
}

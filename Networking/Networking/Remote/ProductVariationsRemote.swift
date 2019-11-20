import Foundation
import Alamofire


/// ProductVariation: Remote Endpoints
///
public class ProductVariationsRemote: Remote {

    /// Retrieves all of the `ProductVariation`s available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote product variations.
    ///     - productID: Product for which we'll fetch remote product variations.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of product variations to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAllProductVariations(for siteID: Int64,
                                         productID: Int64,
                                         context: String? = nil,
                                         pageNumber: Int = Default.pageNumber,
                                         pageSize: Int = Default.pageSize,
                                         completion: @escaping ([ProductVariation]?, Error?) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context ?? Default.context
        ]

        let path = "\(Path.products)/\(productID)/variations"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: Int(siteID), path: path, parameters: parameters)
        let mapper = ProductVariationListMapper(siteID: siteID, productID: productID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
public extension ProductVariationsRemote {
    enum Default {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = 1
        public static let context: String = "view"
    }

    private enum Path {
        static let products   = "products"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
    }
}

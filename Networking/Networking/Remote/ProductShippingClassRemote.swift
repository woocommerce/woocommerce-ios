import Foundation
import Alamofire

/// ProductShippingClass: Remote Endpoints
///
public class ProductShippingClassRemote: Remote {

    /// Retrieves all of the `ProductShippingClass`s available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote models.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of models to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadAll(for siteID: Int64,
                        context: String? = nil,
                        pageNumber: Int = Default.pageNumber,
                        pageSize: Int = Default.pageSize,
                        completion: @escaping ([ProductShippingClass]?, Error?) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context ?? Default.context
        ]

        let path = "\(Path.models)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: Int(siteID), path: path, parameters: parameters)
        let mapper = ProductShippingClassListMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
public extension ProductShippingClassRemote {
    enum Default {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = 1
        public static let context: String = "view"
    }

    private enum Path {
        static let models = "products/shipping_classes"
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
    }
}

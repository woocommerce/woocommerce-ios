// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation
import Alamofire

/// ProductVariation: Remote Endpoints
///
public class ProductVariationRemote: Remote {

    /// Retrieves all of the `ProductVariation`s available.
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
                        completion: @escaping ([ProductVariation]?, Error?) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.contextKey: context ?? Default.context
        ]

        let path = "\(Path.models)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: Int(siteID), path: path, parameters: parameters)
        let mapper = ProductVariationListMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }


    /// Retrieves a specific `ProductVariation`.
    ///
    /// - Parameters:
    ///     - siteID: Site which hosts the ProductVariation.
    ///     - remoteID: Identifier of the ProductVariation on the server.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func loadProduct(for siteID: Int, remoteID: Int, completion: @escaping (ProductVariation?, Error?) -> Void) {
        let path = "\(Path.models)/\(remoteID)"
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: nil)
        let mapper = ProductVariationMapper(siteID: siteID)

        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
public extension ProductVariationRemote {
    enum Default {
        public static let pageSize: Int   = 25
        public static let pageNumber: Int = 1
        public static let context: String = "view"
    }

    private enum Path {
        static let models = "" // TODO: update path
    }

    private enum ParameterKey {
        static let page: String       = "page"
        static let perPage: String    = "per_page"
        static let contextKey: String = "context"
    }
}

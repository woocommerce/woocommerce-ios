import Foundation

/// Customer: Remote Endpoints
///
public class CustomerRemote: Remote {

    /// Retrieves all of the customers available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote customers.
    ///     - context: view or edit. Scope under which the request is made;
    ///                determines fields present in response. Default is view.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of Customers to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func getAllCustomers(for siteID: Int64,
                                context: ContextType = Default.context,
                                pageNumber: Int = Default.firstPageNumber,
                                pageSize: Int = Default.pageSize,
                                completion: @escaping (Result<[Customer], Error>) -> Void) {
        let parameters = [
            ParameterKey.context: context.rawValue,
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize)
        ]

        let path = Path.customers
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path, parameters: parameters)
        let mapper = CustomersListMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
public extension CustomerRemote {

    enum ContextType: String {
        case view
        case edit
    }

    enum Default {
        public static let context: ContextType = .view
        public static let pageSize: Int        = 25
        public static let firstPageNumber: Int = Remote.Default.firstPageNumber
    }

    private enum Path {
        static let customers = "customers"
    }

    private enum ParameterKey {
        static let context: String = "context"
        static let page: String    = "page"
        static let perPage: String = "per_page"
    }
}

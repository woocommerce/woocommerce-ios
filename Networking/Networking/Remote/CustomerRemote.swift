import Foundation

/// Customer: Remote Endpoints
///
public class CustomerRemote: Remote {

    /// Create a customer.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll create a customer.
    ///     - customer: The Customer model used to create the custom entity for the request.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func createCustomer(for siteID: Int64,
                               customer: Customer,
                               completion: @escaping (Result<Customer, Error>) -> Void) {
        let path = Path.customers
        let mapper = CustomerMapper(siteID: siteID)

        do {
            let encodedJson = try mapper.map(customer: customer)
            let parameters: [String: Any]? = try JSONSerialization.jsonObject(with: encodedJson, options: []) as? [String: Any]
            let request = JetpackRequest(wooApiVersion: .mark3, method: .post, siteID: siteID, path: path, parameters: parameters)

            enqueue(request, mapper: mapper, completion: completion)
        } catch {
            completion(.failure(error))
            DDLogError("Unable to serialize data for refunds: \(error)")
        }
    }

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

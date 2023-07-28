import Foundation

public class WCAnalyticsCustomerRemote: Remote {
    /// Retrieves a `Customer` collection from `/wc-analytics/customers` based on the `?search=` parameter
    /// Or doesn't perform the request if the`?search=` parameter is empty
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the customer.
    ///     - name: Name of the customer that will be retrieved
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of customers to be retrieved per page.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func searchCustomers(for siteID: Int64, name: String, completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
        // If there's no search term, we can exit and avoid the HTTP request
        if name == "" {
            return
        }

        enqueueRequest(with: ["search": name], siteID: siteID, completion: completion)
    }

    /// Loads a paginated list of customers
    /// 
    public func loadCustomers(for siteID: Int64,
                                pageNumber: Int = 1,
                                pageSize: Int = 25,
                                completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
        let parameters = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.orderBy: "name",
            ParameterKey.order: "asc",
            ParameterKey.filterEmpty: "email",
        ]

        enqueueRequest(with: parameters, siteID: siteID, completion: completion)
    }

    private func enqueueRequest(with parameters: [String: Any], siteID: Int64, completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
        let path = "customers"
        let request = JetpackRequest(
            wooApiVersion: .wcAnalytics,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: parameters,
            availableAsRESTRequest: true
        )

        let mapper = WCAnalyticsCustomerMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: { result in
            switch result {
            case .success(let customers):
                completion(.success(customers))
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}

private extension WCAnalyticsCustomerRemote {
    enum ParameterKey {
        static let page        = "page"
        static let perPage     = "per_page"
        static let orderBy     = "orderby"
        static let order       = "order"
        static let search      = "search"
        static let filterEmpty = "filter_empty"
    }
}

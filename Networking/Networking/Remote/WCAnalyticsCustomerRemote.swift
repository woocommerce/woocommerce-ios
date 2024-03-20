import Foundation

public class WCAnalyticsCustomerRemote: Remote {
    /// Retrieves a `Customer` collection from `/wc-analytics/customers` based on the `?search=` parameter
    /// Or doesn't perform the request if the`?search=` parameter is empty
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the customer.
    ///     - pageNumber: Number of page that should be retrieved.
    ///     - pageSize: Number of customers to be retrieved per page.
    ///     - orderby: Field to use for sorting the customers to be retrieved.
    ///     - order: Sort order for customers to be retrieved (ascending or descending).
    ///     - keyword: Name of the customer that will be retrieved
    ///     - filter: Filter by which the search will be performed. Possible values: all (in WC 8.0.0+), name, username, email
    ///     - filterEmptyEmails: Filter customers to retrieve only those with email addresses.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func searchCustomers(for siteID: Int64,
                                pageNumber: Int = 1,
                                pageSize: Int = 25,
                                orderby: OrderBy,
                                order: Order,
                                keyword: String,
                                filter: String,
                                filterEmpty: FilterEmpty? = nil,
                                completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.orderBy: orderby.rawValue,
            ParameterKey.order: order.rawValue,
            ParameterKey.filterEmpty: filterEmpty?.rawValue,
            ParameterKey.search: keyword,
            ParameterKey.searchBy: filter
        ].compactMapValues { $0 }

        enqueueRequest(with: parameters, siteID: siteID, completion: completion)
    }

    /// Loads a paginated list of customers
    ///
    public func loadCustomers(for siteID: Int64,
                              pageNumber: Int = 1,
                              pageSize: Int = 25,
                              orderby: OrderBy,
                              order: Order,
                              filterEmpty: FilterEmpty? = nil,
                              completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
        let parameters: [String: Any] = [
            ParameterKey.page: String(pageNumber),
            ParameterKey.perPage: String(pageSize),
            ParameterKey.orderBy: orderby.rawValue,
            ParameterKey.order: order.rawValue,
            ParameterKey.filterEmpty: filterEmpty?.rawValue
        ].compactMapValues { $0 }
        enqueueRequest(with: parameters, siteID: siteID, completion: completion)
    }
}

private extension WCAnalyticsCustomerRemote {
    func enqueueRequest(with parameters: [String: Any], siteID: Int64, completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
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

public extension WCAnalyticsCustomerRemote {
    /// `orderby` parameter values
    enum OrderBy: String {
        case name
        case dateLastActive = "date_last_active"
    }

    /// `order` parameter values
    enum Order: String {
        case asc
        case desc
    }

    /// `filter_empty` parameter values
    enum FilterEmpty: String {
        case email
    }
}

private extension WCAnalyticsCustomerRemote {
    enum ParameterKey {
        static let page        = "page"
        static let perPage     = "per_page"
        static let orderBy     = "orderby"
        static let order       = "order"
        static let search      = "search"
        static let searchBy    = "searchby"
        static let filterEmpty = "filter_empty"
    }
}

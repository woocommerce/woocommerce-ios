import Foundation

public class WCAnalyticsCustomerRemote: Remote {

    /// Retrieves the `Customer`collection from `/wc-analytics/customers`
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the customers.
    ///     - completion: Closure to be executed upon completion.
    ///
    func retrieveCustomers(for siteID: Int64, completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
        let path = "customers"
        let request = JetpackRequest(
            wooApiVersion: .wcAnalytics,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: nil
        )

        let mapper = WCAnalyticsCustomerMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }

    /// Retrieves a `Customer` collection from `/wc-analytics/customers` based on the `?search=` parameter
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the customer.
    ///     - name: Name of the customer that will be retrieved
    ///     - completion: Closure to be executed upon completion.
    ///
    func retrieveCustomerByName(for siteID: Int64, with name: String, completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
        let path = "customers?search=\(name)"
        let request = JetpackRequest(
            wooApiVersion: .wcAnalytics,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: nil
        )

        let mapper = WCAnalyticsCustomerMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}

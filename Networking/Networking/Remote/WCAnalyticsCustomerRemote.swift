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
    /// Or doesn't perform the request if the`?search=` parameter is empty
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the customer.
    ///     - name: Name of the customer that will be retrieved
    ///     - completion: Closure to be executed upon completion.
    ///
    func retrieveCustomerByName(for siteID: Int64, with name: String, completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
        // If there's no search term, we can exit and avoid the HTTP request
        if name == "" {
            return
        }
        let path = "customers?search=\(name)"
        let request = JetpackRequest(
            wooApiVersion: .wcAnalytics,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: nil
        )

        let mapper = WCAnalyticsCustomerMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: { result in
            switch result {
            case .success(let customers):
                // If the successful response contains a Customer with the same name as the search term,
                // return a new collection with only these values
                if customers.contains(where: { $0.name == name }) {
                    let matchCustomers = customers.filter { $0.name == name }
                    completion(.success(matchCustomers))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        })
    }
}

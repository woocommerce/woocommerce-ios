import Foundation

public class WCAnalyticsCustomerRemote: Remote {
    /// Retrieves a `Customer` collection from `/wc-analytics/customers` based on the `?search=` parameter
    /// Or doesn't perform the request if the`?search=` parameter is empty
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch the customer.
    ///     - name: Name of the customer that will be retrieved
    ///     - completion: Closure to be executed upon completion.
    ///
    public func searchCustomers(for siteID: Int64, name: String, completion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
        // If there's no search term, we can exit and avoid the HTTP request
        if name == "" {
            return
        }

        let path = "customers"
        let request = JetpackRequest(
            wooApiVersion: .wcAnalytics,
            method: .get,
            siteID: siteID,
            path: path,
            parameters: ["search": name],
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

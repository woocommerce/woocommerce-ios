import Foundation

public class CustomerRemote: Remote {
    /// Retrieves a `Customer`
    ///
    /// - Parameters:
    ///     - customerID: ID of the customer that will be retrieved
    ///     - siteID: Site for which we'll fetch the customer.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func retrieveCustomer(for siteID: Int64, with customerID: Int64, completion: @escaping (Result<Customer, Error>) -> Void) {
        let path = "customers/\(customerID)"
        let request = JetpackRequest(wooApiVersion: .mark3,
                                     method: .get,
                                     siteID: siteID,
                                     path: path,
                                     parameters: nil,
                                     availableAsRESTRequest: true)

        let mapper = CustomerMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}

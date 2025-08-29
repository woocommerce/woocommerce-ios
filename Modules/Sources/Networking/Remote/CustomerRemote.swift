import Foundation

public class CustomerRemote: Remote {
    /// Retrieves a `Customer`
    ///
    /// - Parameters:
    ///     - userID: ID of the registered WordPress user (customer) that will be retrieved.
    ///     - siteID: Site for which we'll fetch the customer.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func retrieveCustomer(for siteID: Int64, with userID: Int64, completion: @escaping (Result<Customer, Error>) -> Void) {
        let path = "customers/\(userID)"
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

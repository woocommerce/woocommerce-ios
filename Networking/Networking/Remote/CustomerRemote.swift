import Foundation

/// Customer: Remote Endpoints
///
public class CustomerRemote: Remote {

    /// Retrieves all of the customers available.
    ///
    /// - Parameters:
    ///     - siteID: Site for which we'll fetch remote customers.
    ///     - completion: Closure to be executed upon completion.
    ///
    public func getAllCustomers(for siteID: Int64,
                                completion: @escaping (Result<[Customer], Error>) -> Void) {
        let path = Path.customers
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: siteID, path: path)
        let mapper = CustomersListMapper(siteID: siteID)
        enqueue(request, mapper: mapper, completion: completion)
    }
}


// MARK: - Constants
//
private extension CustomerRemote {

    private enum Path {
        static let customers = "customers"
    }
}

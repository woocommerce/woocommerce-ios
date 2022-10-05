import Foundation
import Networking
import Storage

public final class WCAnalyticsCustomerStore: Store {

    private let remote: WCAnalyticsCustomerRemote

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: WCAnalyticsCustomerRemote) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Attempts to retrieve a `WCAnalyticsCustomer` collection  from a site based on an input keyword,
    /// Returns the `[WCAnalyticsCustomer]` object upon success, or an `Error`.
    /// - Parameters:
    ///   - siteID: The site for which customers should be fetched.
    ///   - keyword: Keyword to perform the search for WCAnalyticsCustomer to be fetched.
    ///   - onCompletion: Invoked when the operation finishes.
    ///
    func retrieveCustomers(
        for siteID: Int64,
        with keyword: String,
        onCompletion: @escaping (Result<[WCAnalyticsCustomer], Error>) -> Void) {
            remote.retrieveCustomersByName(for: siteID, with: keyword) { result in
                switch result {
                case .success(let customers):
                    onCompletion(.success(customers))
                case .failure(let error):
                    onCompletion(.failure(error))
                }
            }
    }
}

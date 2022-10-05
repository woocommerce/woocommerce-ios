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

    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
            self.init(dispatcher: dispatcher,
                      storageManager: storageManager,
                      network: network,
                      remote: WCAnalyticsCustomerRemote(network: network)
            )
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: WCAnalyticsCustomerAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    /// - action: An action to handle. Must be a `WCAnalyticsCustomerAction`
    override public func onAction(_ action: Action) {
        guard let action = action as? WCAnalyticsCustomerAction else {
            assertionFailure("WCAnalyticsCustomerStore received an unsupported action")
            return
        }
        switch action {
        case .retrieveCustomers(siteID: let siteID, keyword: let keyword, onCompletion: let onCompletion):
            retrieveCustomers(for: siteID, with: keyword, onCompletion: onCompletion)
        }
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

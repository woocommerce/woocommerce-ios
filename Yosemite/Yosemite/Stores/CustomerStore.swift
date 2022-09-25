import Foundation
import Networking
import Storage

public final class CustomerStore: Store {

    private let remote: CustomerRemote

    init(dispatcher: Dispatcher,
         storageManager: StorageManagerType,
         network: Network,
         remote: CustomerRemote) {
        self.remote = remote
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    public override convenience init(dispatcher: Dispatcher,
                                     storageManager: StorageManagerType,
                                     network: Network) {
        self.init(dispatcher: dispatcher,
                  storageManager: storageManager,
                  network: network,
                  remote: CustomerRemote(network: network))
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: CustomerAction.self)
    }

    /// Receives and executes Actions.
    /// - Parameters:
    ///   - action: An action to handle. Must be a `CouponAction`
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? CustomerAction else {
            assertionFailure("CouponStore received an unsupported action")
            return
        }
        switch action {
        case .retrieveCustomer(siteID: let siteID, customerID: let customerID, onCompletion: let onCompletion):
            retrieveCustomer(for: siteID, with: customerID, onCompletion: onCompletion)
        }
    }

    func retrieveCustomer(
        for siteID: Int64,
        with customerID: Int64,
        onCompletion: @escaping (Result<Customer, Error>) -> Void) {
            // Want to return this Result<Customer, Error> to a completion handler
            // So we can call it across the app and extend for CD
            remote.retrieveCustomer(for: siteID, with: customerID) { result in
                switch result {
                case .failure(let error):
                    onCompletion(.failure(error))
                case .success(let customer):
                    onCompletion(.success(customer))
                }
            }
        }
}

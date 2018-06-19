import Foundation
import Networking


// MARK: - OrderStore
//
public class OrderStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: OrderAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? OrderAction else {
            assertionFailure("OrderStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveOrders(let siteId, let onCompletion):
            retrieveOrders(siteId: siteId, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
extension OrderStore  {

    /// Retrieves the orders associated with a given Site ID (if any!).
    ///
    func retrieveOrders(siteId: Int, onCompletion: @escaping ([Order]?, Error?) -> Void) {
        let remote = OrdersRemote(network: network)

        remote.loadAllOrders(for: siteId) { (orders, error) in
            guard let orders = orders else {
                onCompletion(nil, error)
                return
            }

            onCompletion(orders, nil)
        }
    }
}

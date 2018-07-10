import Foundation
import Networking


// MARK: - OrderNoteStore
//
public class OrderNoteStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: OrderNoteAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? OrderNoteAction else {
            assertionFailure("OrderNoteStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveOrderNotes(let siteId, let orderId, let onCompletion):
            retrieveOrderNotes(siteId: siteId, orderId: orderId, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
extension OrderNoteStore  {

    /// Retrieves the order notes associated with the provided Site ID & Order ID (if any!).
    ///
    func retrieveOrderNotes(siteId: Int, orderId: Int, onCompletion: @escaping ([OrderNote]?, Error?) -> Void) {
        let remote = OrdersRemote(network: network)
        remote.loadOrderNotes(for: siteId, orderID: orderId) { (orderNotes, error) in
            guard let orderNotes = orderNotes else {
                onCompletion(nil, error)
                return
            }

            onCompletion(orderNotes, nil)
        }
    }
}

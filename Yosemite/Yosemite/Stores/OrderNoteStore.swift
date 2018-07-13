import Foundation
import Networking
import Storage

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


// MARK: - Persistance
//
private extension OrderNoteStore {

    /// Updates (OR Inserts) the specified ReadOnly OrderNote Entity into the Storage Layer.
    ///
    func upsertStoredOrderNote(readOnlyOrderNote: Networking.OrderNote) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        let storageOrderNote = storage.loadOrderNote(noteID: readOnlyOrderNote.noteID) ?? storage.insertNewObject(ofType: Storage.OrderNote.self)
        storageOrderNote.update(with: readOnlyOrderNote)
        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified ReadOnly OrderNote Entities into the Storage Layer.
    ///
    func upsertStoredOrderNotes(readOnlyOrderNotes: [Networking.OrderNote]) {
        assert(Thread.isMainThread)

        let storage = storageManager.viewStorage
        for readOnlyOrderNote in readOnlyOrderNotes {
            let storageOrderNote = storage.loadOrderNote(noteID: readOnlyOrderNote.noteID) ?? storage.insertNewObject(ofType: Storage.OrderNote.self)
            storageOrderNote.update(with: readOnlyOrderNote)
        }

        storage.saveIfNeeded()
    }
}

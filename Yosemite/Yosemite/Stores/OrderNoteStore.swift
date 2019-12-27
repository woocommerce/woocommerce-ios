import Foundation
import Networking
import Storage

// MARK: - OrderNoteStore
//
public class OrderNoteStore: Store {

    /// Shared private StorageType for use during then entire OrderNotes sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

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
            retrieveOrderNotes(siteID: siteId, orderID: orderId, onCompletion: onCompletion)
        case .addOrderNote(let siteId, let orderId, let isCustomerNote, let note, let onCompletion):
            addOrderNote(siteID: siteId, orderID: orderId, isCustomerNote: isCustomerNote, note: note, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension OrderNoteStore {

    /// Retrieves the order notes associated with the provided Site ID & Order ID (if any!).
    ///
    func retrieveOrderNotes(siteID: Int64, orderID: Int64, onCompletion: @escaping ([OrderNote]?, Error?) -> Void) {
        let remote = OrdersRemote(network: network)
        remote.loadOrderNotes(for: siteID, orderID: orderID) { [weak self] (orderNotes, error) in
            guard let orderNotes = orderNotes else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredOrderNotesInBackground(readOnlyOrderNotes: orderNotes, orderID: orderID) {
                onCompletion(orderNotes, nil)
            }
        }
    }

    /// Adds a single order note and associates it with the provided siteID and orderID.
    ///
    func addOrderNote(siteID: Int64, orderID: Int64, isCustomerNote: Bool, note: String, onCompletion: @escaping (OrderNote?, Error?) -> Void) {
        let remote = OrdersRemote(network: network)
        remote.addOrderNote(for: siteID, orderID: orderID, isCustomerNote: isCustomerNote, with: note) { [weak self] (orderNote, error) in
            guard let note = orderNote else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredOrderNotesInBackground(readOnlyOrderNotes: [note], orderID: orderID) {
                onCompletion(note, nil)
            }
        }
    }
}


// MARK: - Persistence
//
extension OrderNoteStore {

    /// Updates (OR Inserts) the specified ReadOnly OrderNote Entity into the Storage Layer.
    ///
    func upsertStoredOrderNoteInBackground(readOnlyOrderNote: Networking.OrderNote, orderID: Int64, onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.saveNote(derivedStorage, readOnlyOrderNote, orderID)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly OrderNote Entities into the Storage Layer.
    ///
    func upsertStoredOrderNotesInBackground(readOnlyOrderNotes: [Networking.OrderNote], orderID: Int64, onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            for readOnlyOrderNote in readOnlyOrderNotes {
                self.saveNote(derivedStorage, readOnlyOrderNote, orderID)
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Using the provided StorageType, update or insert a Storage.OrderNote using the provided ReadOnly
    /// OrderNote. This func does *not* persist any unsaved changes to storage.
    ///
    private func saveNote(_ storage: StorageType, _ readOnlyOrderNote: OrderNote, _ orderID: Int64) {
        if let existingStorageNote = storage.loadOrderNote(noteID: readOnlyOrderNote.noteID) {
            existingStorageNote.update(with: readOnlyOrderNote)
            return
        }

        guard let storageOrder = storage.loadOrder(orderID: orderID) else {
            DDLogWarn("⚠️ Could not persist the OrderNote with ID \(readOnlyOrderNote.noteID) — unable to retrieve stored order with ID \(orderID).")
            return
        }

        let newStorageNote = storage.insertNewObject(ofType: Storage.OrderNote.self)
        newStorageNote.update(with: readOnlyOrderNote)
        newStorageNote.order = storageOrder
        storageOrder.addToNotes(newStorageNote)
    }
}

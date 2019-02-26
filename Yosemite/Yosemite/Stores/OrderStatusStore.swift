import Foundation
import Networking
import Storage
import CocoaLumberjack


// MARK: - OrderStatusStore
//
public class OrderStatusStore: Store {

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: OrderStatusAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? OrderStatusAction else {
            assertionFailure("OrderStatusStore received an unsupported action")
            return
        }

        switch action {
        case .retrieveOrderStatuses(let siteID, let onCompletion):
            retrieveOrderStatuses(siteID: siteID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension OrderStatusStore {

    /// Retrieves the order statuses associated with the provided Site ID (if any!).
    ///
    func retrieveOrderStatuses(siteID: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = ReportRemote(network: network)
        remote.loadOrderStatuses(for: siteID) { [weak self] (orderStatuses, error) in
            guard let orderStatuses = orderStatuses else {
                onCompletion(error)
                return
            }

            self?.upsertStoredOrderStatuses(siteID: siteID, readOnlyOrderStatuses: orderStatuses)
            onCompletion(nil)
        }
    }
}


// MARK: - Persistence
//
extension OrderStatusStore {

    /// Updates (OR Inserts) the specified ReadOnly OrderStatus Entities into the Storage Layer.
    ///
    func upsertStoredOrderStatuses(siteID: Int, readOnlyOrderStatuses: [Networking.OrderStatus]) {
        assert(Thread.isMainThread)
        let storage = storageManager.viewStorage

        // Upsert the settings from the read-only site settings
        for readOnlyItem in readOnlyOrderStatuses {
            if let existingStorageItem = storage.loadOrderStatus(siteID: siteID, slug: readOnlyItem.slug) {
                existingStorageItem.update(with: readOnlyItem)
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.OrderStatus.self)
                newStorageItem.update(with: readOnlyItem)
            }
        }

        // Now, remove any objects that exist in storageOrderStatuses but not in readOnlyOrderStatuses
        if let storageOrderStatuses = storage.loadOrderStatuses(siteID: siteID) {
            storageOrderStatuses.forEach({ storageItem in
                if readOnlyOrderStatuses.first(where: { $0.slug == storageItem.slug } ) == nil {
                    storage.deleteObject(storageItem)
                }
            })
        }

        storage.saveIfNeeded()
    }
}

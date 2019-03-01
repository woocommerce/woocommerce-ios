import Foundation
import Networking
import Storage
import CocoaLumberjack


// MARK: - OrderStatusStore
//
public class OrderStatusStore: Store {

    /// Shared private StorageType for use during then entire Orders sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

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
    func retrieveOrderStatuses(siteID: Int, onCompletion: @escaping ([OrderStatus]?, Error?) -> Void) {
        let remote = ReportRemote(network: network)
        remote.loadOrderStatuses(for: siteID) { [weak self] (orderStatuses, error) in
            guard let orderStatuses = orderStatuses else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredOrdersInBackground(siteID: siteID, readOnlyOrderStatuses: orderStatuses, onCompletion: {
                onCompletion(orderStatuses, nil)
            })
        }
    }
}


// MARK: - Persistence
//
private extension OrderStatusStore {

    /// Updates (OR Inserts) the specified ReadOnly Order Status Entities
    /// *in a background thread*. onCompletion will be called on the main thread!
    ///
    private func upsertStoredOrdersInBackground(siteID: Int,
                                                readOnlyOrderStatuses: [Networking.OrderStatus],
                                                onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            for readOnlyItem in readOnlyOrderStatuses {
                let storageStatusItem = derivedStorage.loadOrderStatus(siteID: readOnlyItem.siteID, slug: readOnlyItem.slug) ?? derivedStorage.insertNewObject(ofType: Storage.OrderStatus.self)
                storageStatusItem.update(with: readOnlyItem)
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}

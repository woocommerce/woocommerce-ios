import Foundation
import Networking
import Storage


// MARK: - OrderStatusStore
//
public class OrderStatusStore: Store {
    private let remote: ReportRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = ReportRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

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
        case .resetStoredOrderStatuses(let onCompletion):
            resetStoredOrderStatuses(onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension OrderStatusStore {

    /// Retrieves the order statuses associated with the provided Site ID (if any!).
    ///
    func retrieveOrderStatuses(siteID: Int64, onCompletion: @escaping (Result<[OrderStatus], Error>) -> Void) {
        remote.loadOrdersTotals(for: siteID) { result in
            switch result {
            case .success(let orderStatuses):
                self.upsertStatusesInBackground(siteID: siteID, readOnlyOrderStatuses: orderStatuses) {
                    onCompletion(.success(orderStatuses))
                }
            case .failure(let error):
                onCompletion(.failure(error))
            }
        }
    }

    /// Nukes all of the Stored OrderStatuses.
    ///
    func resetStoredOrderStatuses(onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            storage.deleteAllObjects(ofType: Storage.OrderStatus.self)
        }, completion: {
            DDLogDebug("OrderStatuses deleted")
            onCompletion()
        }, on: .main)
    }
}


// MARK: - Persistence
//
extension OrderStatusStore {

    /// Updates (OR Inserts) the specified ReadOnly Order Status Entities
    /// *in a background thread*. onCompletion will be called on the main thread!
    ///
    func upsertStatusesInBackground(siteID: Int64, readOnlyOrderStatuses: [Networking.OrderStatus], onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            for readOnlyItem in readOnlyOrderStatuses {
                let storageStatusItem = storage.loadOrderStatus(siteID: readOnlyItem.siteID, slug: readOnlyItem.slug) ??
                storage.insertNewObject(ofType: Storage.OrderStatus.self)
                storageStatusItem.update(with: readOnlyItem)
            }

            // Now, remove any objects that exist in storage but not in readOnlyOrderStatuses
            if let storageStatuses = storage.loadOrderStatuses(siteID: siteID) {
                storageStatuses.forEach({ storageStatus in
                    if readOnlyOrderStatuses.first(where: { $0.slug == storageStatus.slug } ) == nil {
                        storage.deleteObject(storageStatus)
                    }
                })
            }
        }, completion: onCompletion, on: .main)
    }
}

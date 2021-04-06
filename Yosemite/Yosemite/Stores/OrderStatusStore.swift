import Foundation
import Networking
import Storage


// MARK: - OrderStatusStore
//
public class OrderStatusStore: Store {
    private let remote: ReportRemote

    /// Shared private StorageType for use during then entire Orders sync process
    ///
    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.writerDerivedStorage
    }()

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
    func retrieveOrderStatuses(siteID: Int64, onCompletion: @escaping ([OrderStatus]?, Error?) -> Void) {
        remote.loadOrderStatuses(for: siteID) { [weak self] (orderStatuses, error) in
            guard let orderStatuses = orderStatuses else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStatusesInBackground(siteID: siteID, readOnlyOrderStatuses: orderStatuses) {
                onCompletion(orderStatuses, nil)
            }
        }
    }

    /// Nukes all of the Stored OrderStatuses.
    ///
    func resetStoredOrderStatuses(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.OrderStatus.self)
        storage.saveIfNeeded()
        DDLogDebug("OrderStatuses deleted")

        onCompletion()
    }
}


// MARK: - Persistence
//
extension OrderStatusStore {

    /// Updates (OR Inserts) the specified ReadOnly Order Status Entities
    /// *in a background thread*. onCompletion will be called on the main thread!
    ///
    func upsertStatusesInBackground(siteID: Int64, readOnlyOrderStatuses: [Networking.OrderStatus], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            for readOnlyItem in readOnlyOrderStatuses {
                let storageStatusItem = derivedStorage.loadOrderStatus(siteID: readOnlyItem.siteID, slug: readOnlyItem.slug) ??
                                        derivedStorage.insertNewObject(ofType: Storage.OrderStatus.self)
                storageStatusItem.update(with: readOnlyItem)
            }

            // Now, remove any objects that exist in storage but not in readOnlyOrderStatuses
            if let storageStatuses = derivedStorage.loadOrderStatuses(siteID: siteID) {
                storageStatuses.forEach({ storageStatus in
                    if readOnlyOrderStatuses.first(where: { $0.slug == storageStatus.slug } ) == nil {
                        derivedStorage.deleteObject(storageStatus)
                    }
                })
            }
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }
}

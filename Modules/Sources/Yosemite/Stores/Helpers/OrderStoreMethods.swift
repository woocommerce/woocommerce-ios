import Foundation
import Networking
import Storage

/// OrderStoreMethods extracts functionality of OrderStore that needs be reused within Yosemite
/// OrderStoreMethods is intentionally internal not to be exposed outside the module
///
/// periphery: ignore
internal protocol OrderStoreMethodsProtocol {
    func deleteOrder(siteID: Int64,
                     order: Order,
                     deletePermanently: Bool,
                     onCompletion: @escaping (Result<Order, Error>) -> Void)
}

internal class OrderStoreMethods: OrderStoreMethodsProtocol {
    private let remote: OrdersRemote
    private let storageManager: StorageManagerType

    init(
        storageManager: StorageManagerType,
        remote: OrdersRemote
    ) {
        self.remote = remote
        self.storageManager = storageManager
    }

    /// Deletes a given order.
    /// Extracted from OrderStore.deleteOrder() implementation.
    ///
    func deleteOrder(siteID: Int64, order: Order, deletePermanently: Bool, onCompletion: @escaping (Result<Order, Error>) -> Void) {
        // Optimistically delete the order from storage
        deleteStoredOrder(siteID: siteID, orderID: order.orderID)

        remote.deleteOrder(for: siteID, orderID: order.orderID, force: deletePermanently) { [weak self] result in
            switch result {
            case .success:
                onCompletion(result)
            case .failure:
                // Revert optimistic deletion unless the order is an auto-draft (shouldn't be stored)
                guard order.status != .autoDraft else {
                    return onCompletion(result)
                }
                self?.upsertStoredOrdersInBackground(readOnlyOrders: [order], onCompletion: {
                    onCompletion(result)
                })
            }
        }
    }
}

// MARK: - Storage Methods

private extension OrderStoreMethods {
    /// Deletes any Storage.Order with the specified OrderID
    /// Extracted from OrderStore.deleteStoredOrder()
    ///
    func deleteStoredOrder(siteID: Int64, orderID: Int64, onCompletion: (() -> Void)? = nil) {
        storageManager.performAndSave({ storage in
            guard let order = storage.loadOrder(siteID: siteID, orderID: orderID) else {
                return
            }
            storage.deleteObject(order)
        }, completion: onCompletion, on: .main)
    }

    /// Updates (OR Inserts) the specified ReadOnly Order Entities *in a background thread*.
    /// Extracted from OrderStore.upsertStoredOrdersInBackground()
    ///
    func upsertStoredOrdersInBackground(readOnlyOrders: [Networking.Order],
                                        removeAllStoredOrders: Bool = false,
                                        onCompletion: (() -> Void)? = nil) {
        storageManager.performAndSave({ [weak self] derivedStorage in
            guard let self else { return }
            if removeAllStoredOrders {
                derivedStorage.deleteAllObjects(ofType: Storage.Order.self)
            }
            upsertStoredOrders(readOnlyOrders: readOnlyOrders, in: derivedStorage)
        }, completion: onCompletion, on: .main)
    }

    /// Updates (OR Inserts) the specified ReadOnly Order Entities into the Storage Layer.
    /// Extracted from OrderStore.upsertStoredOrders()
    ///
    func upsertStoredOrders(readOnlyOrders: [Networking.Order],
                            insertingSearchResults: Bool = false,
                            in storage: StorageType) {
        let useCase = OrdersUpsertUseCase(storage: storage)
        useCase.upsert(readOnlyOrders, insertingSearchResults: insertingSearchResults)
    }
}

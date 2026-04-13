import Foundation
import Networking
import Storage


// MARK: - OrderFulfillmentStore
//
public class OrderFulfillmentStore: Store {
    private let remote: OrderFulfillmentsRemote

    public override init(dispatcher: Dispatcher, storageManager: StorageManagerType, network: Network) {
        self.remote = OrderFulfillmentsRemote(network: network)
        super.init(dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: OrderFulfillmentAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? OrderFulfillmentAction else {
            assertionFailure("OrderFulfillmentStore received an unsupported action")
            return
        }

        switch action {
        case .synchronizeOrderFulfillments(let siteID, let orderID, let onCompletion):
            synchronizeOrderFulfillments(siteID: siteID, orderID: orderID, onCompletion: onCompletion)
        }
    }
}


// MARK: - Services
//
private extension OrderFulfillmentStore {

    func synchronizeOrderFulfillments(siteID: Int64, orderID: Int64, onCompletion: @escaping (Error?) -> Void) {
        remote.loadOrderFulfillments(for: siteID, orderID: orderID) { [weak self] (fulfillments, error) in
            guard let readOnlyFulfillments = fulfillments else {
                onCompletion(error)
                return
            }

            self?.upsertOrderFulfillmentsInBackground(
                siteID: siteID,
                orderID: orderID,
                readOnlyFulfillments: readOnlyFulfillments
            ) {
                onCompletion(nil)
            }
        }
    }
}


// MARK: - Persistence
//
extension OrderFulfillmentStore {

    /// Updates (OR Inserts) the specified ReadOnly OrderFulfillment Entities into the Storage Layer *in a background thread*.
    /// onCompletion will be called on the main thread.
    ///
    func upsertOrderFulfillmentsInBackground(siteID: Int64,
                                             orderID: Int64,
                                             readOnlyFulfillments: [Networking.OrderFulfillment],
                                             onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            guard let storageOrder = storage.loadOrder(siteID: siteID, orderID: orderID) else {
                return
            }

            let storageFulfillments = storage.loadOrderFulfillmentList(
                siteID: siteID,
                orderID: orderID
            )

            // Upsert fulfillments from the remote response
            for readOnlyFulfillment in readOnlyFulfillments {
                let storageFulfillment = storageFulfillments?.first(
                    where: {
                        $0.fulfillmentID == readOnlyFulfillment.fulfillmentID
                    }
                ) ?? storage.insertNewObject(
                    ofType: Storage.OrderFulfillment.self
                )
                storageFulfillment.update(with: readOnlyFulfillment)
                storageFulfillment.order = storageOrder
            }

            // Remove stale entries not present in the remote response
            storageFulfillments?.forEach({ storageFulfillment in
                if readOnlyFulfillments.first(
                    where: {
                        $0.fulfillmentID == storageFulfillment.fulfillmentID
                    }
                ) == nil {
                    storage.deleteObject(storageFulfillment)
                }
            })
        }, completion: onCompletion, on: .main)
    }
}

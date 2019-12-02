import Foundation
import Networking
import Storage


// MARK: - RefundStore
//
public class RefundStore: Store {

    private lazy var sharedDerivedStorage: StorageType = {
        return storageManager.newDerivedStorage()
    }()

    /// Registers for supported Actions.
    ///
    override public func registerSupportedActions(in dispatcher: Dispatcher) {
        dispatcher.register(processor: self, for: RefundAction.self)
    }

    /// Receives and executes Actions.
    ///
    override public func onAction(_ action: Action) {
        guard let action = action as? RefundAction else {
            assertionFailure("RefundStore received an unsupported action")
            return
        }

        switch action {
        case .createRefund(let siteID, let orderID, let refund, let onCompletion):
            createRefund(siteID: siteID, orderID: orderID, refund: refund, onCompletion: onCompletion)
        case .retrieveRefund(let siteID, let orderID, let refundID, let onCompletion):
            retrieveRefund(siteID: siteID, orderID: orderID, refundID: refundID, onCompletion: onCompletion)
        case .retrieveRefunds(let siteID, let orderID, let refundIDs, let onCompletion):
            retrieveRefunds(siteID: siteID, orderID: orderID, refundIDs: refundIDs, onCompletion: onCompletion)
        case .synchronizeRefunds(let siteID, let orderID, let pageNumber, let pageSize, let onCompletion):
            synchronizeRefunds(siteID: siteID, orderID: orderID, pageNumber: pageNumber, pageSize: pageSize, onCompletion: onCompletion)
        case .resetStoredRefunds(let onCompletion):
            resetStoredRefunds(onCompletion: onCompletion)
        }
    }
}


// MARK: - Services!
//
private extension RefundStore {

    /// Creates a new Refund.
    ///
    func createRefund(siteID: Int, orderID: Int, refund: Refund, onCompletion: @escaping (Refund?, Error?) -> Void) {
        let remote = RefundsRemote(network: network)

        remote.createRefund(for: siteID, by: orderID, refund: refund) { [weak self] (refund, error) in
            guard let refund = refund else {
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredRefundsInBackground(readOnlyRefunds: [refund]) {
                onCompletion(refund, nil)
            }
        }
    }

    /// Retrieves a single Refund by ID.
    ///
    func retrieveRefund(siteID: Int, orderID: Int, refundID: Int, onCompletion: @escaping (Networking.Refund?, Error?) -> Void) {
        let remote = RefundsRemote(network: network)

        remote.loadRefund(siteID: siteID, orderID: orderID, refundID: refundID) { [weak self] (refund, error) in
            guard let refund = refund else {
                if case NetworkError.notFound? = error {
                    self?.deleteStoredRefund(siteID: siteID, orderID: orderID, refundID: refundID)
                }
                onCompletion(nil, error)
                return
            }

            self?.upsertStoredRefundsInBackground(readOnlyRefunds: [refund]) {
                onCompletion(refund, nil)
            }
        }
    }

    /// Retrieves all Refunds by an orderID.
    ///
    func retrieveRefunds(siteID: Int, orderID: Int, refundIDs: [Int], onCompletion: @escaping (Error?) -> Void) {
        let remote = RefundsRemote(network: network)

        remote.loadRefunds(for: siteID, by: orderID, with: refundIDs) { [weak self] (refunds, error) in
            guard let refunds = refunds else {
                onCompletion(error)
                return
            }

            self?.upsertStoredRefundsInBackground(readOnlyRefunds: refunds) {
                onCompletion(nil)
            }
        }
    }

    /// Synchronizes the refunds associated with a given orderID
    ///
    func synchronizeRefunds(siteID: Int, orderID: Int, pageNumber: Int, pageSize: Int, onCompletion: @escaping (Error?) -> Void) {
        let remote = RefundsRemote(network: network)

        remote.loadAllRefunds(for: siteID, by: orderID) { [weak self] (refunds, error) in
            guard let refunds = refunds else {
                onCompletion(error)
                return
            }

            self?.upsertStoredRefundsInBackground(readOnlyRefunds: refunds) {
                onCompletion(nil)
            }
        }
    }

    /// Deletes all of the stored Refunds.
    ///
    func resetStoredRefunds(onCompletion: () -> Void) {
        let storage = storageManager.viewStorage
        storage.deleteAllObjects(ofType: Storage.Refund.self)
        storage.saveIfNeeded()
        DDLogDebug("Refunds deleted")

        onCompletion()
    }
}


// MARK: - Storage: Refund
//
private extension RefundStore {

    /// Deletes any Storage.Refund with the specified `siteID`, `orderID`, and `refundID`
    ///
    func deleteStoredRefund(siteID: Int, orderID: Int, refundID: Int) {
        let storage = storageManager.viewStorage
        guard let refund = storage.loadRefund(siteID: siteID, orderID: orderID, refundID: refundID) else {
            return
        }

        storage.deleteObject(refund)
        storage.saveIfNeeded()
    }

    /// Updates (OR Inserts) the specified ReadOnly Refund Entities *in a background thread*.
    /// onCompletion will be called on the main thread!
    ///
    func upsertStoredRefundsInBackground(readOnlyRefunds: [Networking.Refund], onCompletion: @escaping () -> Void) {
        let derivedStorage = sharedDerivedStorage
        derivedStorage.perform {
            self.upsertStoredRefunds(readOnlyRefunds: readOnlyRefunds, in: derivedStorage)
        }

        storageManager.saveDerivedType(derivedStorage: derivedStorage) {
            DispatchQueue.main.async(execute: onCompletion)
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly Refund Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyRefunds: Remote Refunds to be persisted.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredRefunds(readOnlyRefunds: [Networking.Refund], in storage: StorageType) {
        for readOnlyRefund in readOnlyRefunds {
            let storageRefund = storage.loadRefund(siteID: readOnlyRefund.siteID, orderID: readOnlyRefund.orderID, refundID: readOnlyRefund.refundID) ??
                storage.insertNewObject(ofType: Storage.Refund.self)

            storageRefund.update(with: readOnlyRefund)

            handleOrderItemRefunds(readOnlyRefund, storageRefund, storage)
        }
    }

    /// Updates, inserts, or prunes the provided StorageRefund's refunded order items
    /// using the provided read-only OrderItemRefunds
    ///
    func handleOrderItemRefunds(_ readOnlyRefund: Networking.Refund, _ storageRefund: Storage.Refund, _ storage: StorageType) {
        var storageItem: Storage.OrderItemRefund
        let siteID = readOnlyRefund.siteID
        let refundID = readOnlyRefund.refundID

        // Upsert items from the read-only refund
        for readOnlyItem in readOnlyRefund.items {
            if let existingStorageItem = storage.loadRefundItem(siteID: siteID, refundID: refundID, itemID: readOnlyItem.itemID) {
                existingStorageItem.update(with: readOnlyItem)
                storageItem = existingStorageItem
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.OrderItemRefund.self)
                newStorageItem.update(with: readOnlyItem)
                storageRefund.addToItems(newStorageItem)
                storageItem = newStorageItem
            }

            // upsert the taxes from the read-only item
            handleOrderItemTaxRefunds(readOnlyItem, storageItem, storage)
        }

        // Now, remove any objects that exist in storageRefund.items but not in readOnlyRefund.items
        storageRefund.items?.forEach { storageItem in
            if readOnlyRefund.items.first(where: { $0.itemID == storageItem.itemID && $0.name == storageItem.name } ) == nil {
                storageRefund.removeFromItems(storageItem)
                storage.deleteObject(storageItem)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrderItemRefund's taxes using the provided read-only OrderItemRefund
    ///
    private func handleOrderItemTaxRefunds(_ readOnlyItem: Networking.OrderItemRefund, _ storageItem: Storage.OrderItemRefund, _ storage: StorageType) {
        let itemID = readOnlyItem.itemID

        // Upsert the taxes from the read-only orderItem
        for readOnlyTax in readOnlyItem.taxes {
            if let existingStorageTax = storage.loadRefundItemTax(itemID: itemID, taxID: readOnlyTax.taxID) {
                existingStorageTax.update(with: readOnlyTax)
            } else {
                let newStorageTax = storage.insertNewObject(ofType: Storage.OrderItemTaxRefund.self)
                newStorageTax.update(with: readOnlyTax)
                storageItem.addToTaxes(newStorageTax)
            }
        }

        // Now, remove any objects that exist in storageOrder.items but not in readOnlyOrder.items
        storageItem.taxes?.forEach { storageTax in
            if readOnlyItem.taxes.first(where: { $0.taxID == storageTax.taxID } ) == nil {
                storageItem.removeFromTaxes(storageTax)
                storage.deleteObject(storageTax)
            }
        }
    }
}

// MARK: - Unit Testing Helpers
//
extension RefundStore {

    /// Unit Testing Helper: Updates or Inserts the specified ReadOnly Refund in a given Storage Layer.
    ///
    func upsertStoredRefund(readOnlyRefund: Networking.Refund, in storage: StorageType) {
        upsertStoredRefunds(readOnlyRefunds: [readOnlyRefund], in: storage)
    }
}

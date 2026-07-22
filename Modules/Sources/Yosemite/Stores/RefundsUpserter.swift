import Foundation
import Networking
import Storage

/// Persists remote `Refund` entities to storage. Shared by the v3 `RefundStore` action path
/// and the v4 `RefundService`, so both write refunds (items, shipping lines, taxes) identically.
///
struct RefundsUpserter {
    private let storageManager: StorageManagerType

    init(storageManager: StorageManagerType) {
        self.storageManager = storageManager
    }

    /// Updates (OR Inserts) the specified ReadOnly Refund Entities *in a background thread*.
    /// onCompletion will be called on the main thread!
    ///
    func upsertStoredRefundsInBackground(siteID: Int64,
                                         orderID: Int64,
                                         readOnlyRefunds: [Networking.Refund],
                                         staleRefundIDs: [Int64] = [],
                                         onCompletion: @escaping () -> Void) {
        storageManager.performAndSave({ storage in
            let storedRefunds = storage.loadRefunds(siteID: siteID, orderID: orderID)
            if staleRefundIDs.isEmpty == false {
                self.deleteStaleRefunds(staleRefundIDs: staleRefundIDs,
                                        storedRefunds: storedRefunds,
                                        in: storage)
            }
            self.upsertStoredRefunds(siteID: siteID,
                                     orderID: orderID,
                                     storedRefunds: storedRefunds,
                                     readOnlyRefunds: readOnlyRefunds,
                                     in: storage)
        }, completion: onCompletion, on: .main)
    }

    /// Async variant of `upsertStoredRefundsInBackground`.
    ///
    func upsertStoredRefunds(siteID: Int64,
                             orderID: Int64,
                             readOnlyRefunds: [Networking.Refund]) async {
        await withCheckedContinuation { continuation in
            upsertStoredRefundsInBackground(siteID: siteID,
                                            orderID: orderID,
                                            readOnlyRefunds: readOnlyRefunds) {
                continuation.resume()
            }
        }
    }

    /// Updates (OR Inserts) the specified ReadOnly Refund Entities into the Storage Layer.
    ///
    /// - Parameters:
    ///     - readOnlyRefunds: Remote Refunds to be persisted.
    ///     - storage: Where we should save all the things!
    ///
    func upsertStoredRefunds(siteID: Int64,
                             orderID: Int64,
                             storedRefunds: [Storage.Refund],
                             readOnlyRefunds: [Networking.Refund],
                             in storage: StorageType) {
        for readOnlyRefund in readOnlyRefunds {
            let storageRefund = storedRefunds.first(where: { $0.refundID == readOnlyRefund.refundID }) ?? storage.insertNewObject(ofType: Storage.Refund.self)

            storageRefund.update(with: readOnlyRefund)

            handleOrderItemRefunds(readOnlyRefund, storageRefund, storage)
            handleShippingLines(readOnlyRefund, storageRefund, storage)
        }
    }

    /// Deletes all refunds from an order when their IDs are contained in the provided `staleRefundIDs` array.
    ///
    func deleteStaleRefunds(staleRefundIDs: [Int64],
                            storedRefunds: [Storage.Refund],
                            in storage: StorageType) {
        let staleRefunds = storedRefunds.filter { staleRefundIDs.contains($0.refundID) }
        staleRefunds.forEach { stale in
            storage.deleteObject(stale)
        }
    }
}

private extension RefundsUpserter {

    /// Updates, inserts, or prunes the provided StorageRefund's refunded order items
    /// using the provided read-only OrderItemRefunds
    ///
    func handleOrderItemRefunds(_ readOnlyRefund: Networking.Refund, _ storageRefund: Storage.Refund, _ storage: StorageType) {
        var storageItem: Storage.OrderItemRefund

        let storedRefundItems = storageRefund.items

        // Upsert items from the read-only refund
        for readOnlyItem in readOnlyRefund.items {
            if let existingStorageItem = storedRefundItems?.first(where: { $0.itemID == readOnlyItem.itemID }) {
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
        storedRefundItems?.forEach { storageItem in
            if !readOnlyRefund.items.contains(where: { $0.itemID == storageItem.itemID && $0.name == storageItem.name }) {
                storageRefund.removeFromItems(storageItem)
                storage.deleteObject(storageItem)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageRefund's shipping lines.
    ///
    func handleShippingLines(_ readOnlyRefund: Networking.Refund, _ storageRefund: Storage.Refund, _ storage: StorageType) {

        let storedShippingLines = storageRefund.shippingLines

        // Upsert shipping lines from the read-only refund
        for readOnlyShippingLine in readOnlyRefund.shippingLines ?? [] {
            // Load or create a shipping line from the read only version
            let storageShippingLine: Storage.ShippingLine = {
                guard let existingShippingLine = storedShippingLines?.first(where: { $0.shippingID == readOnlyShippingLine.shippingID }) else {
                    let newShippingLine = storage.insertNewObject(ofType: Storage.ShippingLine.self)
                    storageRefund.addToShippingLines(newShippingLine)
                    return newShippingLine
                }
                return existingShippingLine
            }()

            storageShippingLine.update(with: readOnlyShippingLine)
            handleShippingLineTaxes(readOnlyShippingLine, storageShippingLine, storage)
        }

        // Now, remove any object that exist in storageRefund.shippingLines but not in readOnlyRefund.shippingLines
        storedShippingLines?.forEach { storedShippingLine in
            if let shippingLines = readOnlyRefund.shippingLines, !shippingLines.contains(where: { $0.shippingID == storedShippingLine.shippingID }) {
                storageRefund.removeFromShippingLines(storedShippingLine)
                storage.deleteObject(storedShippingLine)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrderItemRefund's taxes using the provided read-only OrderItemRefund
    ///
    func handleOrderItemTaxRefunds(_ readOnlyItem: Networking.OrderItemRefund, _ storageItem: Storage.OrderItemRefund, _ storage: StorageType) {
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
            if !readOnlyItem.taxes.contains(where: { $0.taxID == storageTax.taxID }) {
                storageItem.removeFromTaxes(storageTax)
                storage.deleteObject(storageTax)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageShippingLine's taxes using the provided read-only ShippingLine
    ///
    func handleShippingLineTaxes(_ readOnlyShippingLine: Networking.ShippingLine, _ storageShippingLine: Storage.ShippingLine, _ storage: StorageType) {
        // Upsert the taxes from the read-only shipping line
        readOnlyShippingLine.taxes.forEach { readyOnlyTax in
            if let storageTax = storage.loadShippingLineTax(shippingID: readOnlyShippingLine.shippingID, taxID: readyOnlyTax.taxID) {
                storageTax.update(with: readyOnlyTax)
            } else {
                let newTax = storage.insertNewObject(ofType: Storage.ShippingLineTax.self)
                storageShippingLine.addToTaxes(newTax)
                newTax.update(with: readyOnlyTax)
            }
        }

        // Now, remove any object that exist in storageShippingLine.taxes but not in readOnlyShippingLine.taxes
        storageShippingLine.taxes?.forEach { storedTax in
            if !readOnlyShippingLine.taxes.contains(where: { $0.taxID == storedTax.taxID }) {
                storageShippingLine.removeFromTaxes(storedTax)
                storage.deleteObject(storedTax)
            }
        }
    }
}

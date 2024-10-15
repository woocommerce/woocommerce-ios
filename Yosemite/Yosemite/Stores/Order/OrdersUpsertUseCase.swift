import Storage
import Networking

/// Upserts `Networking.Order` objects into Storage.
///
/// This UseCase should always be used when inserting or updating Orders since it encapsulates
/// some complex business logic when persisting orders.
///
struct OrdersUpsertUseCase {
    private let storage: StorageType

    /// Initializes a new UseCase.
    ///
    /// - Parameter storage: A derived `StorageType`.
    init(storage: StorageType) {
        self.storage = storage
    }

    /// Updates or inserts the given `Networking.Order` objects.
    ///
    /// - Parameter insertingSearchResults: Indicates if the "Newly Inserted Entities" should be
    ///                                     marked as "Search Results Only".
    ///
    @discardableResult
    func upsert(_ readOnlyOrders: [Networking.Order], insertingSearchResults: Bool = false) -> [Storage.Order] {
        let storageOrders = readOnlyOrders.map { readOnlyOrder in
            upsert(readOnlyOrder, insertingSearchResults: insertingSearchResults)
        }

        do {
            // Obtain permenant IDs because Orders are used as results of `FetchResultSnapshotsProvider`.
            try storage.obtainPermanentIDs(for: storageOrders)
        } catch {
            // We will just ignore errors for now. The refactoring cost of propagating this error
            // does not seem to be worth it at the moment because this method is usually called
            // inside a `StorageType.perform()` block. I don't even know where to begin. ¯\_(ツ)_/¯
            //
            // In the future, we should probably refactor the way we handle Storage errors so
            // they are propagated to the user instead of doing fatalError() like in saveIfNeeded.
            //
            DDLogError("Failed to obtain permanent IDs for \(Storage.Order.entityName): \(error)")
        }

        return storageOrders
    }

    private func upsert(_ readOnlyOrder: Networking.Order, insertingSearchResults: Bool = false) -> Storage.Order {
        let storageOrder = storage.loadOrder(siteID: readOnlyOrder.siteID, orderID: readOnlyOrder.orderID)
            ?? storage.insertNewObject(ofType: Storage.Order.self)
        storageOrder.update(with: readOnlyOrder)

        // Are we caching Search Results? Did this order exist before?
        storageOrder.exclusiveForSearch = insertingSearchResults && (storageOrder.isInserted || storageOrder.exclusiveForSearch)

        handleOrderItems(readOnlyOrder, storageOrder, storage)
        handleOrderCoupons(readOnlyOrder, storageOrder, storage)
        handleOrderFees(readOnlyOrder, storageOrder, storage)
        handleOrderShippingLines(readOnlyOrder, storageOrder, storage)
        handleOrderRefundsCondensed(readOnlyOrder, storageOrder, storage)
        handleOrderTaxes(readOnlyOrder, storageOrder, storage)
        handleOrderCustomFields(readOnlyOrder, storageOrder, storage)
        handleOrderGiftCards(readOnlyOrder, storageOrder, storage)
        handleOrderAttributionInfo(readOnlyOrder, storageOrder, storage)

        return storageOrder
    }

    /// Updates, inserts, or prunes the provided StorageOrder's items using the provided read-only Order's items
    ///
    private func handleOrderItems(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        var storageItem: Storage.OrderItem
        let siteID = readOnlyOrder.siteID
        let orderID = readOnlyOrder.orderID

        // Upsert the items from the read-only order
        for readOnlyItem in readOnlyOrder.items {
            if let existingStorageItem = storageOrder.orderItemsArray.first(where: { $0.itemID == readOnlyItem.itemID }) {
                existingStorageItem.update(with: readOnlyItem)
                storageItem = existingStorageItem
            } else {
                let newStorageItem = storage.insertNewObject(ofType: Storage.OrderItem.self)
                newStorageItem.update(with: readOnlyItem)
                storageOrder.addToItems(newStorageItem)
                storageItem = newStorageItem
            }

            handleOrderItemAttributes(readOnlyItem, storageItem, storage)
            handleOrderItemAddOns(readOnlyItem, storageItem, storage)
            handleOrderItemTaxes(readOnlyItem, storageItem, storage)
        }

        // Now, remove any objects that exist in storageOrder.items but not in readOnlyOrder.items
        storageOrder.orderItemsArray.forEach { storageItem in
            if readOnlyOrder.items.first(where: { $0.itemID == storageItem.itemID } ) == nil {
                storageOrder.removeFromItems(storageItem)
                storage.deleteObject(storageItem)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrderItem's attributes using the provided read-only OrderItem
    ///
    private func handleOrderItemAttributes(_ readOnlyItem: Networking.OrderItem, _ storageItem: Storage.OrderItem, _ storage: StorageType) {
        // Removes all the attributes first.
        storageItem.attributesArray.forEach { existingStorageAttribute in
            storage.deleteObject(existingStorageAttribute)
        }

        // Inserts the attributes from the read-only model.
        let storageAttributes: [StorageOrderItemAttribute] = readOnlyItem.attributes
            .map { readOnlyAttribute in
                let storageAttribute = storage.insertNewObject(ofType: Storage.OrderItemAttribute.self)
                storageAttribute.update(with: readOnlyAttribute)
                return storageAttribute
        }
        storageItem.attributes = NSOrderedSet(array: storageAttributes)
    }

    /// Updates, inserts, or prunes the provided StorageOrderItem's add-ons using the provided read-only OrderItem.
    ///
    private func handleOrderItemAddOns(_ readOnlyItem: Networking.OrderItem, _ storageItem: Storage.OrderItem, _ storage: StorageType) {
        // Removes all the add-ons first.
        storageItem.addOnsArray.forEach { existingStorageAddOn in
            storage.deleteObject(existingStorageAddOn)
        }

        // Inserts the add-ons from the read-only model.
        let storageAddOns: [Storage.OrderItemProductAddOn] = readOnlyItem.addOns
            .map { readOnlyAddOn in
                let storageAddOn = storage.insertNewObject(ofType: Storage.OrderItemProductAddOn.self)
                storageAddOn.update(with: readOnlyAddOn)
                return storageAddOn
        }
        storageItem.addOns = NSOrderedSet(array: storageAddOns)
    }

    /// Updates, inserts, or prunes the provided StorageOrderItem's taxes using the provided read-only OrderItem
    ///
    private func handleOrderItemTaxes(_ readOnlyItem: Networking.OrderItem, _ storageItem: Storage.OrderItem, _ storage: StorageType) {
        let itemID = readOnlyItem.itemID

        // Upsert the taxes from the read-only orderItem
        for readOnlyTax in readOnlyItem.taxes {
            if let existingStorageTax = storageItem.taxes?.first(where: { $0.taxID == readOnlyTax.taxID }) {
                existingStorageTax.update(with: readOnlyTax)
            } else {
                let newStorageTax = storage.insertNewObject(ofType: Storage.OrderItemTax.self)
                newStorageTax.update(with: readOnlyTax)
                storageItem.addToTaxes(newStorageTax)
            }
        }

        // Now, remove any objects that exist in storageOrderItem.taxes but not in readOnlyOrderItem.taxes
        storageItem.taxes?.forEach { storageTax in
            if readOnlyItem.taxes.first(where: { $0.taxID == storageTax.taxID } ) == nil {
                storageItem.removeFromTaxes(storageTax)
                storage.deleteObject(storageTax)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's coupons using the provided read-only Order's coupons
    ///
    private func handleOrderCoupons(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Upsert the coupons from the read-only order
        for readOnlyCoupon in readOnlyOrder.coupons {
            if let existingStorageCoupon = storage.loadOrderCoupon(siteID: readOnlyOrder.siteID, couponID: readOnlyCoupon.couponID) {
                existingStorageCoupon.update(with: readOnlyCoupon)
            } else {
                let newStorageCoupon = storage.insertNewObject(ofType: Storage.OrderCoupon.self)
                newStorageCoupon.update(with: readOnlyCoupon)
                storageOrder.addToCoupons(newStorageCoupon)
            }
        }

        // Now, remove any objects that exist in storageOrder.coupons but not in readOnlyOrder.coupons
        storageOrder.coupons?.forEach { storageCoupon in
            if readOnlyOrder.coupons.first(where: { $0.couponID == storageCoupon.couponID } ) == nil {
                storageOrder.removeFromCoupons(storageCoupon)
                storage.deleteObject(storageCoupon)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's fees using the provided read-only Order's fees
    ///
    private func handleOrderFees(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Upsert the coupons from the read-only order
        for readOnlyFee in readOnlyOrder.fees {
            if let existingStorageFee = storage.loadOrderFeeLine(siteID: readOnlyOrder.siteID, feeID: readOnlyFee.feeID) {
                existingStorageFee.update(with: readOnlyFee)
            } else {
                let newStorageFee = storage.insertNewObject(ofType: Storage.OrderFeeLine.self)
                newStorageFee.update(with: readOnlyFee)
                storageOrder.addToFees(newStorageFee)
            }
        }

        // Now, remove any objects that exist in storageOrder.fees but not in readOnlyOrder.fees
        storageOrder.fees?.forEach { storageFee in
            if readOnlyOrder.fees.first(where: { $0.feeID == storageFee.feeID } ) == nil {
                storageOrder.removeFromFees(storageFee)
                storage.deleteObject(storageFee)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's condensed refunds using the provided read-only Order's OrderRefundCondensed
    ///
    private func handleOrderRefundsCondensed(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Upsert the refunds from the read-only order
        for readOnlyRefund in readOnlyOrder.refunds {
            if let existingStorageRefund = storage.loadOrderRefundCondensed(siteID: readOnlyOrder.siteID, refundID: readOnlyRefund.refundID) {
                existingStorageRefund.update(with: readOnlyRefund)
            } else {
                let newStorageRefund = storage.insertNewObject(ofType: Storage.OrderRefundCondensed.self)
                newStorageRefund.update(with: readOnlyRefund)
                storageOrder.addToRefunds(newStorageRefund)
            }
        }

        // Now, remove any objects that exist in storageOrder.OrderRefundCondensed but not in readOnlyOrder.OrderRefundCondensed
        storageOrder.refunds?.forEach { storageRefunds in
            if readOnlyOrder.refunds.first(where: { $0.refundID == storageRefunds.refundID } ) == nil {
                storageOrder.removeFromRefunds(storageRefunds)
                storage.deleteObject(storageRefunds)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's shipping lines using the provided read-only Order's shippingLine
    ///
    private func handleOrderShippingLines(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Upsert the shipping lines from the read-only order
        for readOnlyShippingLine in readOnlyOrder.shippingLines {
            if let existingStorageShippingLine = storage.loadOrderShippingLine(siteID: readOnlyOrder.siteID, shippingID: readOnlyShippingLine.shippingID) {
                existingStorageShippingLine.update(with: readOnlyShippingLine)
                handleShippingLineTaxes(readOnlyShippingLine, existingStorageShippingLine, storage)
            } else {
                let newStorageShippingLine = storage.insertNewObject(ofType: Storage.ShippingLine.self)
                newStorageShippingLine.update(with: readOnlyShippingLine)
                storageOrder.addToShippingLines(newStorageShippingLine)
                handleShippingLineTaxes(readOnlyShippingLine, newStorageShippingLine, storage)
            }
        }

        // Now, remove any objects that exist in storageOrder.shippingLines but not in readOnlyOrder.shippingLines
        storageOrder.shippingLines?.forEach { storageShippingLine in
            if readOnlyOrder.shippingLines.first(where: { $0.shippingID == storageShippingLine.shippingID } ) == nil {
                storageOrder.removeFromShippingLines(storageShippingLine)
                storage.deleteObject(storageShippingLine)
            }
        }
    }

    /// Updates, inserts, or prunes the provided StorageShippingLine's taxes using the provided read-only ShippingLine
    ///
    private func handleShippingLineTaxes(_ readOnlyItem: Networking.ShippingLine, _ storageItem: Storage.ShippingLine, _ storage: StorageType) {
        let shippingID = readOnlyItem.shippingID

        // Upsert the taxes from the read-only orderItem
        for readOnlyTax in readOnlyItem.taxes {
            if let existingStorageTax = storage.loadShippingLineTax(shippingID: shippingID, taxID: readOnlyTax.taxID) {
                existingStorageTax.update(with: readOnlyTax)
            } else {
                let newStorageTax = storage.insertNewObject(ofType: Storage.ShippingLineTax.self)
                newStorageTax.update(with: readOnlyTax)
                storageItem.addToTaxes(newStorageTax)
            }
        }

        // Now, remove any objects that exist in storageItem.taxes but not in readOnlyItem.taxes
        storageItem.taxes?.forEach { storageTax in
            if readOnlyItem.taxes.first(where: { $0.taxID == storageTax.taxID } ) == nil {
                storageItem.removeFromTaxes(storageTax)
                storage.deleteObject(storageTax)
            }
        }
    }

    /// Updates, inserts, or prunes the provided `storageOrder`'s taxes using the provided `readOnlyOrder`'s taxes
    ///
    private func handleOrderTaxes(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Upsert the `taxes` from the `readOnlyOrder`
        readOnlyOrder.taxes.forEach { readOnlyTax in
            if let existingStorageTax = storage.loadOrderTaxLine(siteID: readOnlyOrder.siteID, taxID: readOnlyTax.taxID) {
                existingStorageTax.update(with: readOnlyTax)
            } else {
                let newStorageTax = storage.insertNewObject(ofType: Storage.OrderTaxLine.self)
                newStorageTax.update(with: readOnlyTax)
                storageOrder.addToTaxes(newStorageTax)
            }
        }

        // Now, remove any objects that exist in `storageOrder.taxes` but not in `readOnlyOrder.taxes`
        storageOrder.taxes?.forEach { storageTax in
            if readOnlyOrder.taxes.first(where: { $0.taxID == storageTax.taxID } ) == nil {
                storageOrder.removeFromTaxes(storageTax)
                storage.deleteObject(storageTax)
            }
        }
    }

    /// Updates, inserts, or prunes the provided `storageOrder`'s custom fields using the provided `readOnlyOrder`'s custom fields
    ///
    private func handleOrderCustomFields(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        let storedMetaData = storageOrder.customFields
        // Upsert the `customFields` from the `readOnlyOrder`
        readOnlyOrder.customFields.forEach { readOnlyCustomField in
            if let existingStorageMetaData = storedMetaData?.first(where: { $0.metadataID == readOnlyCustomField.metadataID }) {
                existingStorageMetaData.update(with: readOnlyCustomField)
            } else {
                let newStorageMetaData = storage.insertNewObject(ofType: Storage.MetaData.self)
                newStorageMetaData.update(with: readOnlyCustomField)
                storageOrder.addToCustomFields(newStorageMetaData)
            }
        }

        // Now, remove any objects that exist in `storageOrder.customFields` but not in `readOnlyOrder.customFields`
        storageOrder.customFields?.forEach { storageCustomField in
            if readOnlyOrder.customFields.first(where: { $0.metadataID == storageCustomField.metadataID } ) == nil {
                storageOrder.removeFromCustomFields(storageCustomField)
                storage.deleteObject(storageCustomField)
            }
        }
    }

    /// Updates, inserts, or prunes the provided `storageOrder`'s applied gift cards using the provided `readOnlyOrder`'s custom fields
    ///
    private func handleOrderGiftCards(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        // Remove any objects that exist in `storageOrder.appliedGiftCards` first
        storageOrder.appliedGiftCards?.forEach { existingStorageGiftCard in
            storage.deleteObject(existingStorageGiftCard)
        }

        // Upsert the `appliedGiftCards` from the `readOnlyOrder`
        readOnlyOrder.appliedGiftCards.forEach { readOnlyGiftCard in
            let newStorageGiftCard = storage.insertNewObject(ofType: Storage.OrderGiftCard.self)
            newStorageGiftCard.update(with: readOnlyGiftCard)
            storageOrder.addToAppliedGiftCards(newStorageGiftCard)
        }
    }

    /// Updates, inserts, or prunes the provided StorageOrder's attribution info using the provided read-only Order's attribution info
    ///
    private func handleOrderAttributionInfo(_ readOnlyOrder: Networking.Order, _ storageOrder: Storage.Order, _ storage: StorageType) {
        guard let readOnlyOrderAttributionInfo = readOnlyOrder.attributionInfo else {
            if let existingStorageOrderAttributionInfo = storageOrder.attributionInfo {
                storage.deleteObject(existingStorageOrderAttributionInfo)
            }
            return
        }

        if let existingStorageOrderAttributionInfo = storageOrder.attributionInfo {
            existingStorageOrderAttributionInfo.update(with: readOnlyOrderAttributionInfo)
        } else {
            let newStorageOrderAttributionInfo = storage.insertNewObject(ofType: Storage.OrderAttributionInfo.self)
            newStorageOrderAttributionInfo.update(with: readOnlyOrderAttributionInfo)
            storageOrder.attributionInfo = newStorageOrderAttributionInfo
        }
    }
}

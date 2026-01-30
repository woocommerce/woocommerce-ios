import Foundation

public protocol POSRefundCalculating {
    func buildRefundRequest(
        orderID: Int64,
        selectedItems: [POSRefundableItem],
        reason: String?
    ) -> POSRefundRequest
}

public struct POSRefundableItem {
    public let itemID: Int64
    public let price: Decimal
    public let totalTax: Decimal
    public let originalQuantity: Decimal

    public init(itemID: Int64, price: Decimal, totalTax: Decimal, originalQuantity: Decimal) {
        self.itemID = itemID
        self.price = price
        self.totalTax = totalTax
        self.originalQuantity = originalQuantity
    }
}

public final class POSRefundCalculator: POSRefundCalculating {

    public init() {}

    public func buildRefundRequest(
        orderID: Int64,
        selectedItems: [POSRefundableItem],
        reason: String?
    ) -> POSRefundRequest {
        let groupedItems = groupItemsByID(selectedItems)
        let refundItems = buildRefundRequestItems(from: groupedItems)
        let totalAmount = calculateTotalAmount(from: selectedItems)

        return POSRefundRequest(
            orderID: orderID,
            amount: totalAmount,
            reason: reason,
            items: refundItems
        )
    }
}

// MARK: - Private Helpers

private extension POSRefundCalculator {
    func groupItemsByID(_ items: [POSRefundableItem]) -> [Int64: [POSRefundableItem]] {
        Dictionary(grouping: items, by: { $0.itemID })
    }

    func buildRefundRequestItems(from groupedItems: [Int64: [POSRefundableItem]]) -> [POSRefundRequestItem] {
        groupedItems.compactMap { itemID, items -> POSRefundRequestItem? in
            guard let firstItem = items.first else { return nil }

            let quantity = items.count
            let refundTotal = calculateRefundTotal(for: items)
            let refundTax = calculateRefundTax(for: items)

            return POSRefundRequestItem(
                itemID: itemID,
                quantity: quantity,
                refundTotal: refundTotal,
                refundTax: refundTax
            )
        }
    }

    func calculateTotalAmount(from items: [POSRefundableItem]) -> Decimal {
        let subtotal = items.reduce(Decimal.zero) { $0 + $1.price }
        let tax = calculateTotalTax(for: items)
        return subtotal + tax
    }

    func calculateRefundTotal(for items: [POSRefundableItem]) -> Decimal {
        items.reduce(Decimal.zero) { $0 + $1.price }
    }

    /// Calculates refund tax for a specific item group.
    ///
    /// For full refunds (all units of an item selected), uses the original totalTax
    /// directly to avoid rounding errors.
    ///
    /// For partial refunds, calculates proportionally:
    /// `(selectedCount / originalQuantity) × totalTax`
    func calculateRefundTax(for items: [POSRefundableItem]) -> Decimal {
        guard let firstItem = items.first else { return Decimal.zero }

        let selectedCount = Decimal(items.count)
        let originalQuantity = firstItem.originalQuantity
        let totalTax = firstItem.totalTax

        // Full refund: use original tax to avoid rounding errors
        if selectedCount == originalQuantity {
            return totalTax
        }

        // Partial refund: calculate proportionally
        return (totalTax / originalQuantity) * selectedCount
    }

    func calculateTotalTax(for items: [POSRefundableItem]) -> Decimal {
        let groupedItems = groupItemsByID(items)
        return groupedItems.reduce(Decimal.zero) { total, group in
            total + calculateRefundTax(for: group.value)
        }
    }
}

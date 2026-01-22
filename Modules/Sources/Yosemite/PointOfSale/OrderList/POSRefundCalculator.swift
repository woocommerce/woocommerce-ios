import Foundation

/// Protocol for calculating refund amounts and building refund requests.
public protocol POSRefundCalculating {
    /// Builds a refund request from selected items.
    /// - Parameters:
    ///   - orderID: The order ID for the refund
    ///   - selectedItems: The items selected for refund
    ///   - reason: Optional reason for the refund
    /// - Returns: A POSRefundRequest ready for submission
    func buildRefundRequest(
        orderID: Int64,
        selectedItems: [POSRefundableItem],
        reason: String?
    ) -> POSRefundRequest
}

/// Represents an item that can be refunded, with the necessary data for calculations.
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

/// Calculator for POS refund amounts and request building.
/// Handles grouping items, calculating totals, and proportional tax calculations.
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

    /// Groups selected items by their itemID for consolidated calculations.
    func groupItemsByID(_ items: [POSRefundableItem]) -> [Int64: [POSRefundableItem]] {
        Dictionary(grouping: items, by: { $0.itemID })
    }

    /// Builds refund request items from grouped items.
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

    /// Calculates the total refund amount (subtotal + tax) for all selected items.
    func calculateTotalAmount(from items: [POSRefundableItem]) -> Decimal {
        let subtotal = items.reduce(Decimal.zero) { $0 + $1.price }
        let tax = calculateTotalTax(for: items)
        return subtotal + tax
    }

    /// Calculates the refund subtotal for a group of items (sum of prices).
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

    /// Calculates the total tax for all selected items, grouping by itemID first.
    func calculateTotalTax(for items: [POSRefundableItem]) -> Decimal {
        let groupedItems = groupItemsByID(items)
        return groupedItems.reduce(Decimal.zero) { total, group in
            total + calculateRefundTax(for: group.value)
        }
    }
}

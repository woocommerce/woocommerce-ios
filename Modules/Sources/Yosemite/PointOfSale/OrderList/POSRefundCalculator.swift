import Foundation

public struct POSRefundAmounts {
    public let subtotal: Decimal
    public let tax: Decimal

    public var total: Decimal {
        subtotal + tax
    }

    public init(subtotal: Decimal, tax: Decimal) {
        self.subtotal = subtotal
        self.tax = tax
    }
}

public protocol POSRefundCalculating {
    func buildRefundRequest(
        orderID: Int64,
        selectedItems: [POSRefundableItem],
        reason: String?,
        numberOfDecimals: Int
    ) -> POSRefundRequest

    func calculateRefundAmounts(
        for items: [POSRefundableItem],
        numberOfDecimals: Int
    ) -> POSRefundAmounts
}

public struct POSRefundableItem {
    public let itemID: Int64
    public let lineItemTotal: Decimal
    public let totalTax: Decimal
    public let originalQuantity: Decimal

    public init(itemID: Int64, lineItemTotal: Decimal, totalTax: Decimal, originalQuantity: Decimal) {
        self.itemID = itemID
        self.lineItemTotal = lineItemTotal
        self.totalTax = totalTax
        self.originalQuantity = originalQuantity
    }
}

public final class POSRefundCalculator: POSRefundCalculating {

    public init() {}

    public func buildRefundRequest(
        orderID: Int64,
        selectedItems: [POSRefundableItem],
        reason: String?,
        numberOfDecimals: Int
    ) -> POSRefundRequest {
        let groupedItems = groupItemsByID(selectedItems)
        let refundItems = buildRefundRequestItems(from: groupedItems, numberOfDecimals: numberOfDecimals)
        let totalAmount = calculateTotalAmount(from: selectedItems, numberOfDecimals: numberOfDecimals)

        return POSRefundRequest(
            orderID: orderID,
            amount: totalAmount,
            reason: reason,
            items: refundItems
        )
    }

    public func calculateRefundAmounts(for items: [POSRefundableItem], numberOfDecimals: Int) -> POSRefundAmounts {
        let subtotal = calculateSubtotal(for: items, numberOfDecimals: numberOfDecimals)
        let tax = calculateTotalTax(for: items, numberOfDecimals: numberOfDecimals)
        return POSRefundAmounts(subtotal: subtotal, tax: tax)
    }
}

// MARK: - Private Helpers

private extension POSRefundCalculator {
    func groupItemsByID(_ items: [POSRefundableItem]) -> [Int64: [POSRefundableItem]] {
        Dictionary(grouping: items, by: { $0.itemID })
    }

    func buildRefundRequestItems(from groupedItems: [Int64: [POSRefundableItem]], numberOfDecimals: Int) -> [POSRefundRequestItem] {
        groupedItems.compactMap { itemID, items -> POSRefundRequestItem? in
            guard items.first != nil else { return nil }

            let quantityToRefund = items.count
            let refundTotal = calculateRefundTotal(for: items, numberOfDecimals: numberOfDecimals)
            let refundTax = calculateRefundTax(for: items, numberOfDecimals: numberOfDecimals)

            return POSRefundRequestItem(
                itemID: itemID,
                quantity: quantityToRefund,
                refundTotal: refundTotal,
                refundTax: refundTax
            )
        }
    }

    func calculateTotalAmount(from items: [POSRefundableItem], numberOfDecimals: Int) -> Decimal {
        let subtotal = calculateSubtotal(for: items, numberOfDecimals: numberOfDecimals)
        let tax = calculateTotalTax(for: items, numberOfDecimals: numberOfDecimals)
        return roundDecimal(subtotal + tax, scale: numberOfDecimals)
    }

    func calculateSubtotal(for items: [POSRefundableItem], numberOfDecimals: Int) -> Decimal {
        let groupedItems = groupItemsByID(items)
        return groupedItems.reduce(Decimal.zero) { total, group in
            total + calculateRefundTotal(for: group.value, numberOfDecimals: numberOfDecimals)
        }
    }

    /// Calculates refund subtotal for a specific item group.
    ///
    /// For full refunds (all units of an item selected), uses the original lineItemTotal
    /// directly to match the order total exactly.
    ///
    /// For partial refunds, calculates proportionally: (selectedCount / originalQuantity) × lineItemTotal
    func calculateRefundTotal(for items: [POSRefundableItem], numberOfDecimals: Int) -> Decimal {
        guard let firstItem = items.first else { return Decimal.zero }

        let selectedCount = Decimal(items.count)
        let originalQuantity = firstItem.originalQuantity
        let lineItemTotal = firstItem.lineItemTotal

        // Guard against division by zero
        guard originalQuantity > 0 else { return Decimal.zero }

        // Full refund: use original lineItemTotal to match order exactly
        if selectedCount == originalQuantity {
            return lineItemTotal
        }

        // Partial refund: calculate proportionally
        let proportionalTotal = (lineItemTotal / originalQuantity) * selectedCount
        return roundDecimal(proportionalTotal, scale: numberOfDecimals)
    }

    /// Calculates refund tax for a specific item group.
    ///
    /// For full refunds (all units of an item selected), uses the original totalTax
    /// directly to avoid rounding errors.
    ///
    /// For partial refunds, calculates per-unit tax with high precision,
    /// then multiplies by quantity and rounds to the specified decimals.
    func calculateRefundTax(for items: [POSRefundableItem], numberOfDecimals: Int) -> Decimal {
        guard let firstItem = items.first else { return Decimal.zero }

        let selectedCount = Decimal(items.count)
        let originalQuantity = firstItem.originalQuantity
        let totalTax = firstItem.totalTax

        // Guard against division by zero
        guard originalQuantity > 0 else { return Decimal.zero }

        // Full refund: use original tax to avoid rounding errors
        if selectedCount == originalQuantity {
            return totalTax
        }

        // Partial refund: calculate per-unit tax with high precision, then multiply
        let perUnitTax = totalTax / originalQuantity
        let refundTax = perUnitTax * selectedCount
        return roundDecimal(refundTax, scale: numberOfDecimals)
    }

    func calculateTotalTax(for items: [POSRefundableItem], numberOfDecimals: Int) -> Decimal {
        let groupedItems = groupItemsByID(items)
        return groupedItems.reduce(Decimal.zero) { total, group in
            total + calculateRefundTax(for: group.value, numberOfDecimals: numberOfDecimals)
        }
    }

    func roundDecimal(_ value: Decimal, scale: Int) -> Decimal {
        var result = Decimal()
        var mutableValue = value
        NSDecimalRound(&result, &mutableValue, scale, .plain)
        return result
    }
}

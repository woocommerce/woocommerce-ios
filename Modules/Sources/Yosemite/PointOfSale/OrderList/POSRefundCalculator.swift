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
    /// `true` for lines that don't have a unit/quantity concept and refund as a single lump sum
    /// (e.g. order fee lines / custom amounts). When true, the calculator emits the line as a
    /// single request item with `quantity = 0` and uses `lineItemTotal`/`totalTax` directly.
    public let isLumpSum: Bool

    public init(itemID: Int64,
                lineItemTotal: Decimal,
                totalTax: Decimal,
                originalQuantity: Decimal,
                isLumpSum: Bool = false) {
        self.itemID = itemID
        self.lineItemTotal = lineItemTotal
        self.totalTax = totalTax
        self.originalQuantity = originalQuantity
        self.isLumpSum = isLumpSum
    }
}

public final class POSRefundCalculator: POSRefundCalculating {

    public init() {}

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

import Foundation
import Yosemite
import WooFoundation

/// Creates a `Refund` object ready to be used  on `RefundStore.createRefund` action
///
struct RefundCreationUseCase {

    /// Total amount to be refunded.
    ///
    let amount: String

    /// Reason of the refund.
    ///
    let reason: String?

    /// Whether payment refund on the payment gateway should be attempted or not.
    ///
    let automaticallyRefundsPayment: Bool

    /// Line items to be refunded, currently only order items are suported
    ///
    let items: [RefundableOrderItem]

    /// Shipping lines to be refunded, `empty` if shipping will not be refunded.
    ///
    let shippingLines: [ShippingLine]

    /// Fees to be refunded, `empty` if fees will not be refunded.
    ///
    let fees: [OrderFeeLine]

    /// Currency formatted needed for decimal calculations
    ///
    let currencyFormatter: CurrencyFormatter
    let numberOfDecimals: Int

    /// Creates a `Refund` object ready to be used  on `RefundStore.createRefund` action
    ///
    func createRefund() -> Refund {
        return Refund(refundID: .min,
                      orderID: .min,
                      siteID: .min,
                      dateCreated: .distantPast,
                      amount: amount,
                      reason: reason ?? "",
                      refundedByUserID: .min,
                      isAutomated: nil,
                      createAutomated: automaticallyRefundsPayment,
                      items: createRefundItems(),
                      shippingLines: [])
    }

    /// Returns an array of `OrderItemRefund` based on the provided refundable items, shipping line and order fee lines
    ///
    func createRefundItems() -> [OrderItemRefund] {
        var refundItems = items.filter { $0.quantity > 0 }.map {
            Self.productLine(for: $0, currencyFormatter: currencyFormatter, numberOfDecimals: numberOfDecimals)
        }

        if shippingLines.isNotEmpty {
            refundItems += createShippingItems(from: shippingLines)
        }

        if fees.isNotEmpty {
            refundItems += createFeeItems(from: fees)
        }

        return capped(refundItems).compactMap { line in
            let gross = (Decimal(string: line.total) ?? .zero) + line.taxes.reduce(.zero) { $0 + (Decimal(string: $1.total) ?? .zero) }
            guard Self.round(gross, scale: numberOfDecimals) == 0 else { return line }
            guard line.quantity > 0 else { return nil }
            return line.copy(taxes: line.taxes.map { .init(taxID: $0.taxID, subtotal: "", total: "0") }, total: "0")
        }
    }

    /// Returns an `[OrderItemRefund]` based on the provided `[ShippingLine]`
    ///
    private func createShippingItems(from shippingLines: [ShippingLine]) -> [OrderItemRefund] {
        shippingLines.map { shippingLine -> OrderItemRefund in
            OrderItemRefund(itemID: shippingLine.shippingID,
                            quantity: .zero,
                            taxes: createTaxes(from: shippingLine),
                            total: shippingLine.total)
        }
    }

    /// Returns an `[OrderItemRefund]` based on the provided `[OrderFeeLine]`
    ///
    private func createFeeItems(from feeLines: [OrderFeeLine]) -> [OrderItemRefund] {
        feeLines.map { feeLine -> OrderItemRefund in
            OrderItemRefund(itemID: feeLine.feeID,
                            quantity: .zero,
                            taxes: createTaxes(from: feeLine),
                            total: feeLine.total)
        }
    }

    /// Creates an array of `OrderItemTaxRefund` from the tax lines in the provided `ShippingLine`
    ///
    private func createTaxes(from shippingLine: ShippingLine) -> [OrderItemTaxRefund] {
        shippingLine.taxes.map { taxLine -> OrderItemTaxRefund in
            OrderItemTaxRefund(taxID: taxLine.taxID, subtotal: "", total: taxLine.total)
        }
    }

    /// Creates an array of `OrderItemTaxRefund` from the tax lines in the provided `OrderFeeLine`
    ///
    private func createTaxes(from feeLine: OrderFeeLine) -> [OrderItemTaxRefund] {
        feeLine.taxes.map { taxLine -> OrderItemTaxRefund in
            OrderItemTaxRefund(taxID: taxLine.taxID, subtotal: "", total: taxLine.total)
        }
    }

    static func productLine(for refundable: RefundableOrderItem,
                            currencyFormatter: CurrencyFormatter,
                            numberOfDecimals: Int) -> OrderItemRefund {
        let item = refundable.item
        let history = refundable.refundedItems
        let originalGross = (currencyFormatter.convertToDecimal(item.total) as Decimal? ?? .zero)
            + (currencyFormatter.convertToDecimal(item.totalTax) as Decimal? ?? .zero)
        let sign: Decimal = originalGross < 0 ? -1 : 1
        let remainingQuantity = item.quantity + history.reduce(Decimal.zero) { $0 + $1.quantity }
        let isLastQuantity = refundable.decimalQuantity >= remainingQuantity
        func allocation(original: String, refunded: [String]) -> String {
            let originalAmount = (currencyFormatter.convertToDecimal(original) as Decimal? ?? .zero) * sign
            let remaining = max(originalAmount + refunded.reduce(Decimal.zero) {
                $0 + (currencyFormatter.convertToDecimal($1) as Decimal? ?? .zero) * sign
            }, .zero)
            let proportional = item.quantity > 0 ? originalAmount / item.quantity * refundable.decimalQuantity : .zero
            return "\(isLastQuantity ? remaining : min(round(proportional, scale: numberOfDecimals), remaining))"
        }
        let line = OrderItemRefund(itemID: item.itemID, quantity: refundable.decimalQuantity,
                               taxes: item.taxes.map { tax in
                                   OrderItemTaxRefund(taxID: tax.taxID, subtotal: "",
                                                      total: allocation(original: tax.total, refunded: history.flatMap(\.taxes)
                                                        .filter { $0.taxID == tax.taxID }.map(\.total)))
                               },
                               total: allocation(original: item.total, refunded: history.map(\.total)))
        let refundedGross = history.reduce(Decimal.zero) { $0 + (currencyFormatter.convertToDecimal($1.total) as Decimal? ?? .zero)
            + (currencyFormatter.convertToDecimal($1.totalTax) as Decimal? ?? .zero) }
        let remainingGross = max(round((originalGross + refundedGross) * sign, scale: numberOfDecimals), .zero)
        let builder = Self(amount: "\(remainingGross)", reason: nil, automaticallyRefundsPayment: false, items: [], shippingLines: [],
                           fees: [], currencyFormatter: currencyFormatter, numberOfDecimals: numberOfDecimals)
        let allocated = builder.capped([line]).first ?? line
        guard sign < 0 else { return allocated }
        return allocated.copy(taxes: allocated.taxes.map {
            .init(taxID: $0.taxID, subtotal: "", total: "\(-(currencyFormatter.convertToDecimal($0.total) as Decimal? ?? .zero))")
        }, total: "\(-(currencyFormatter.convertToDecimal(allocated.total) as Decimal? ?? .zero))")
    }

    /// Scale every component together when an amount-only refund reduced the order balance.
    /// Round toward zero first, then distribute the remaining minor units without exceeding a component.
    private func capped(_ lines: [OrderItemRefund]) -> [OrderItemRefund] {
        let originals = lines.flatMap { [$0.total] + $0.taxes.map(\.total) }.map {
            currencyFormatter.convertToDecimal($0) as Decimal? ?? .zero
        }
        let total = originals.reduce(.zero, +)
        guard let requested = currencyFormatter.convertToDecimal(amount) as Decimal?,
              Self.round(total, scale: numberOfDecimals) > Self.round(requested, scale: numberOfDecimals), total > 0 else {
            return lines
        }
        let target = max(Self.round(requested, scale: numberOfDecimals), .zero)
        var values = originals.map { Self.round($0 * target / total, scale: numberOfDecimals, mode: $0 < 0 ? .up : .down) }
        let unit = Decimal(sign: .plus, exponent: -numberOfDecimals, significand: 1)
        var remainder = target - values.reduce(.zero, +)
        // Rounding discounts toward zero can put the sum above the target. Reduce
        // positive components before distributing any positive rounding remainder.
        for index in values.indices where remainder < 0 && values[index] > 0 {
            let reduction = min(values[index], -remainder)
            values[index] -= reduction
            remainder += reduction
        }
        let componentLines = lines.indices.flatMap { index in Array(repeating: index, count: 1 + lines[index].taxes.count) }
        let lineLimits = lines.map { line in
            Self.round((Decimal(string: line.total) ?? .zero) + line.taxes.reduce(.zero) {
                $0 + (Decimal(string: $1.total) ?? .zero)
            }, scale: numberOfDecimals)
        }
        for index in values.indices where remainder >= unit {
            let maximum = max(Self.round(originals[index], scale: numberOfDecimals), .zero)
            let lineIndex = componentLines[index]
            let lineTotal = values.indices.filter { componentLines[$0] == lineIndex }.reduce(Decimal.zero) { $0 + values[$1] }
            if values[index] + unit <= maximum && abs(lineTotal + unit) <= abs(lineLimits[lineIndex]) {
                values[index] += unit
                remainder -= unit
            }
        }
        var index = 0
        return lines.map { line in
            let net = values[index]
            index += 1
            let taxes = line.taxes.map { tax in
                defer { index += 1 }
                return OrderItemTaxRefund(taxID: tax.taxID, subtotal: "", total: "\(values[index])")
            }
            return line.copy(taxes: taxes, total: "\(net)")
        }
    }

    static func round(_ value: Decimal, scale: Int, mode: Decimal.RoundingMode = .plain) -> Decimal {
        var value = value
        var result = Decimal.zero
        NSDecimalRound(&result, &value, scale, mode)
        return result
    }
}

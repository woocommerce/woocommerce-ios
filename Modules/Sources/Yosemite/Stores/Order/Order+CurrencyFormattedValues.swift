import Foundation
import WooFoundation

public extension Order {
    private var currencyFormatter: CurrencyFormatter {
        CurrencyFormatter(currencySettings: CurrencySettings())
    }

    var netAmount: String? {
        netAmount(currencyFormatter: currencyFormatter)
    }

    var totalValue: String {
        totalValue(currencyFormatter: currencyFormatter)
    }

    var subtotal: Decimal {
        let subtotal = items.reduce(.zero) { (output, item) in
            let itemSubtotal = Decimal(string: item.subtotal) ?? .zero
            return output + itemSubtotal
        }

        return subtotal
    }

    func netAmount(currencyFormatter: CurrencyFormatter) -> String? {
        guard let netDecimal = calculateNetAmount(currencyFormatter: currencyFormatter) else {
            return nil
        }

        return currencyFormatter.formatAmount(netDecimal, with: currency)
    }

    func paymentTotal(currencyFormatter: CurrencyFormatter) -> String {
        if datePaid == nil {
            return currencyFormatter.formatAmount("0.00", with: currency) ?? String()
        }

        return totalValue(currencyFormatter: currencyFormatter)
    }

    func totalValue(currencyFormatter: CurrencyFormatter) -> String {
        return currencyFormatter.formatAmount(total, with: currency) ?? String()
    }

    func subtotalValue(currencyFormatter: CurrencyFormatter) -> String {
        let subAmount = NSDecimalNumber(decimal: subtotal).stringValue

        return currencyFormatter.formatAmount(subAmount, with: currency) ?? String()
    }

    private func calculateNetAmount(currencyFormatter: CurrencyFormatter) -> NSDecimalNumber? {
        guard let orderTotal = currencyFormatter.convertToDecimal(total) else {
            return .zero
        }

        let totalRefundedUseCase = TotalRefundedCalculationUseCase(order: self, currencyFormatter: currencyFormatter)
        let refundTotal = totalRefundedUseCase.totalRefunded()

        return orderTotal.adding(refundTotal)
    }
}

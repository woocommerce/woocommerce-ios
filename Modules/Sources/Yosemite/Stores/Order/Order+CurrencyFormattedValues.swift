import Foundation
import WooFoundation

public extension Order {
    private var currencyFormatter: CurrencyFormatter {
        CurrencyFormatter(currencySettings: CurrencySettings())
    }

    var netAmount: String? {
        guard let netDecimal = calculateNetAmount() else {
            return nil
        }

        return currencyFormatter.formatAmount(netDecimal, with: currency)
    }

    var paymentTotal: String {
        if datePaid == nil {
            return currencyFormatter.formatAmount("0.00", with: currency) ?? String()
        }

        return totalValue
    }

    var totalValue: String {
        return currencyFormatter.formatAmount(total, with: currency) ?? String()
    }

    private func calculateNetAmount() -> NSDecimalNumber? {
        guard let orderTotal = currencyFormatter.convertToDecimal(total) else {
            return .zero
        }

        let totalRefundedUseCase = TotalRefundedCalculationUseCase(order: self, currencyFormatter: currencyFormatter)
        let refundTotal = totalRefundedUseCase.totalRefunded()

        return orderTotal.adding(refundTotal)
    }
}

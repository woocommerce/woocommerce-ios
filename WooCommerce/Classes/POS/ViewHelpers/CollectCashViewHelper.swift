import Foundation
import SwiftUI
import class WooFoundation.CurrencyFormatter

final class CollectCashViewHelper {
    private let currencyFormatter: CurrencyFormatter = WooFoundation.CurrencyFormatter(currencySettings: ServiceLocator.currencySettings)

    func updatechangeDueMessage(orderTotal: String,
                                textFieldAmountInput: String) -> String? {
        guard let orderDecimal = parseCurrency(orderTotal),
              let inputDecimal = parseCurrency(textFieldAmountInput) else {
            return nil
        }
        if inputDecimal > orderDecimal {
            let changeDue = inputDecimal - orderDecimal
            return String.localizedStringWithFormat(Localization.changeDueMessage, formatAsCurrency(changeDue))
        } else {
            return nil
        }
    }

    func validateAmountOnSubmit(orderTotal: String,
                                textFieldAmountInput: String,
                                onError: (String) -> Void) -> Bool {
        guard let orderDecimal = parseCurrency(orderTotal),
              let inputDecimal = parseCurrency(textFieldAmountInput) else {
            onError(Localization.failedToCollectCashPayment)
            return false
        }

        if inputDecimal < orderDecimal {
            onError(Localization.cashPaymentAmountNotEnough)
            return false
        }
        return true
    }

    private func parseCurrency(_ amountString: String) -> Decimal? {
        // Removes all leading/trailing whitespace, if any
        let sanitized = amountString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Removes currency symbol
        let symbol = ServiceLocator.currencySettings.symbol(from: ServiceLocator.currencySettings.currencyCode)
        let stringWithoutSymbol = sanitized.replacingOccurrences(of: symbol, with: "")

        // Configures the formatter as close as possible to use the Store's settings
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        formatter.groupingSeparator = ServiceLocator.currencySettings.groupingSeparator
        formatter.decimalSeparator = ServiceLocator.currencySettings.decimalSeparator
        formatter.minimumFractionDigits = ServiceLocator.currencySettings.fractionDigits
        formatter.maximumFractionDigits = ServiceLocator.currencySettings.fractionDigits

        // Attempts to parse
        guard let number = formatter.number(from: stringWithoutSymbol) else {
            DDLogError("❌ Failed to parse currency for \(stringWithoutSymbol). Details: \(formatter.logDebugDetails)")
            return nil
        }
        return number.decimalValue
    }

    private func formatAsCurrency(_ amount: Decimal) -> String {
        currencyFormatter.formatAmount(amount) ?? "$0.00"
    }
}

private extension CollectCashViewHelper {
    enum Localization {
        static let changeDueMessage = NSLocalizedString(
            "collectcashviewhelper.changedue",
            value: "Change due: %1$@",
            comment: "Change due when the cash amount entered exceeds the order total." +
            "Reads as 'Change due: $1.23'"
        )
        static let failedToCollectCashPayment = NSLocalizedString(
            "collectcashviewhelper.failedtocollectcashpayment.errormessage",
            value: "Error trying to process payment. Try again.",
            comment: "Error message when the system fails to collect a cash payment."
        )
        static let cashPaymentAmountNotEnough = NSLocalizedString(
            "collectcashviewhelper.cashpaymentamountnotenough.errormessage",
            value: "Amount must be more or equal to total.",
            comment: "Error message when the cash amount entered is less than the order total."
        )
    }
}


extension NumberFormatter {
    var logDebugDetails: String {
        """
        NumberFormatter Details:
        ------------------------
        Number Style: \(self.numberStyle)
        Grouping Separator: \(self.groupingSeparator ?? "nil")
        Decimal Separator: \(self.decimalSeparator ?? "nil")
        Minimum Fraction Digits: \(self.minimumFractionDigits)
        Maximum Fraction Digits: \(self.maximumFractionDigits)
        Locale: \(self.locale.identifier)
        Rounding Mode: \(self.roundingMode)
        Uses Grouping Separator: \(self.usesGroupingSeparator)
        """
    }
}

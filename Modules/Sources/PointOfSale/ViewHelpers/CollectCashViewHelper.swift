import CocoaLumberjackSwift
import Foundation
import SwiftUI
import WooFoundation

final class CollectCashViewHelper {
    private let currencyFormatter: CurrencyFormatter
    private let currencySettings: CurrencySettings

    init(currencySettings: CurrencySettings) {
        self.currencySettings = currencySettings
        self.currencyFormatter = CurrencyFormatter(currencySettings: currencySettings)
    }

    // Configures the formatter as close as possible to use the Store's settings
    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        formatter.groupingSeparator = currencySettings.groupingSeparator
        formatter.decimalSeparator = currencySettings.decimalSeparator
        formatter.minimumFractionDigits = currencySettings.fractionDigits
        formatter.maximumFractionDigits = currencySettings.fractionDigits

        return formatter
    }()

    func updatechangeDueMessage(orderTotal: String,
                                textFieldAmountInput: String) -> String? {
        guard let amount = changeDueAmount(orderTotal: orderTotal, textFieldAmountInput: textFieldAmountInput, includesZeroChange: false) else {
            return nil
        }
        return String.localizedStringWithFormat(Localization.changeDueMessage, formatAsCurrency(amount))
    }

    /// Returns the formatted change due amount without currency symbol.
    func formattedChangeDueAmount(orderTotal: String,
                                  textFieldAmountInput: String) -> String? {
        guard let amount = changeDueAmount(orderTotal: orderTotal, textFieldAmountInput: textFieldAmountInput, includesZeroChange: true),
              let formattedAmount = currencyFormatter.localize(amount) else {
            return nil
        }
        return formattedAmount
    }

    private func changeDueAmount(orderTotal: String,
                                 textFieldAmountInput: String,
                                 includesZeroChange: Bool) -> Decimal? {
        guard let orderDecimal = parseCurrency(orderTotal),
              let inputDecimal = parseCurrency(textFieldAmountInput) else {
            return nil
        }
        if inputDecimal > orderDecimal {
            let changeDue = inputDecimal - orderDecimal
            return changeDue
        } else if includesZeroChange && inputDecimal == orderDecimal {
            return Decimal(0)
        } else {
            return nil
        }
    }

    func isPaymentButtonEnabled(orderTotal: String,
                                textFieldAmountInput: String,
                                isLoading: Bool) -> Bool {
        guard !isLoading else {
            return false
        }

        let inputAmount = textFieldAmountInput.isNotEmpty ? textFieldAmountInput : "0"
        guard let orderDecimal = parseCurrency(orderTotal),
              let inputDecimal = parseCurrency(inputAmount) else {
            return false
        }
        return inputDecimal >= orderDecimal
    }

    func parseCurrency(_ amountString: String) -> Decimal? {
        // Removes all leading/trailing whitespace, if any
        let sanitized = amountString.trimmingCharacters(in: .whitespacesAndNewlines)

        // Removes currency symbol
        let symbol = currencySettings.symbol(from: currencySettings.currencyCode)
        let stringWithoutSymbol = sanitized.replacingOccurrences(of: symbol, with: "")

        // Attempts to parse
        guard let number = numberFormatter.number(from: stringWithoutSymbol) else {
            DDLogError("❌ Failed to parse currency for \(stringWithoutSymbol). Details: \(numberFormatter.logDebugDetails)")
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

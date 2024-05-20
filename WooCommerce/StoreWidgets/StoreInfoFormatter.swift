import Foundation

#if canImport(WooFoundation)
import WooFoundation
#elseif canImport(WooFoundationWatchOS)
import WooFoundationWatchOS
#endif

/// Type to help formatting values for presentation.
///
struct StoreInfoFormatter {
    /// Formats values using the given currency setting.
    ///
    static func formattedAmountString(for amountValue: Decimal, with currencySettings: CurrencySettings?) -> String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings ?? CurrencySettings())
        return currencyFormatter.formatAmount(amountValue) ?? Constants.valuePlaceholderText
    }

    /// Formats values with a compact format using the given currency setting.
    ///
    static func formattedAmountCompactString(for amountValue: Decimal, with currencySettings: CurrencySettings?) -> String {
        let currencyFormatter = CurrencyFormatter(currencySettings: currencySettings ?? CurrencySettings())
        return currencyFormatter.formatHumanReadableAmount(amountValue) ?? Constants.valuePlaceholderText
    }

    /// Formats the conversion as a percentage.
    ///
    static func formattedConversionString(for conversionRate: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .percent
        numberFormatter.minimumFractionDigits = 1

        // do not add 0 fraction digit if the percentage is round
        let minimumFractionDigits = floor(conversionRate * 100.0) == conversionRate * 100.0 ? 0 : 1
        numberFormatter.minimumFractionDigits = minimumFractionDigits
        return numberFormatter.string(from: conversionRate as NSNumber) ?? Constants.valuePlaceholderText
    }

    /// Returns the current time formatted as `10:24 PM` or `22:24` depending on the phone settings.
    ///
    static func currentFormattedTime() -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        timeFormatter.dateStyle = .none
        return timeFormatter.string(from: Date())
    }

    enum Constants {
        static let valuePlaceholderText = "-"
    }
}

import Foundation
import Yosemite


// MARK: - Manual currency formatting
//
public class CurrencyFormatter {
    /// Returns a decimal value from a given string.
    /// - Parameters:
    ///   - stringValue: the string received from the API
    ///
    func convertToDecimal(from stringValue: String) -> NSDecimalNumber? {
        let decimalValue = NSDecimalNumber(string: stringValue)

        guard decimalValue != NSDecimalNumber.notANumber else {
            DDLogError("Error: string input is not a number: \(stringValue)")
            return nil
        }

        return decimalValue
    }

    /// Returns a formatted string for the amount. Does not contain currency symbol.
    /// - Parameters:
    ///     - decimal: a valid NSDecimalNumber, preferably converted using `convertToDecimal()`
    ///     - decimalSeparator: a string representing the user's preferred decimal symbol
    ///     - decimalPosition: an int for positioning the decimal symbol
    ///     - thousandSeparator: a string representing the user's preferred thousand symbol*
    ///       *Assumes thousands grouped by 3, because a user can't indicate a preference and it's a majority default.
    ///       Note this assumption will be wrong for India.
    ///
    func localize(_ decimalAmount: NSDecimalNumber,
                  with decimalSeparator: String? = ".",
                  in decimalPosition: Int = 2,
                  including thousandSeparator: String? = ",") -> String? {

        let numberFormatter = NumberFormatter()
        numberFormatter.usesGroupingSeparator = true
        numberFormatter.groupingSeparator = thousandSeparator
        numberFormatter.decimalSeparator = decimalSeparator
        numberFormatter.groupingSize = 3
        numberFormatter.formatterBehavior = .behavior10_4
        numberFormatter.numberStyle = .decimal
        numberFormatter.generatesDecimalNumbers = true
        numberFormatter.minimumFractionDigits = decimalPosition
        numberFormatter.maximumFractionDigits = decimalPosition
        numberFormatter.negativeSuffix = ""
        numberFormatter.negativePrefix = "-"

        return numberFormatter.string(from: decimalAmount)
    }

    /// Returns a string that displays the amount using all of the specified currency settings
    /// - Parameters:
    ///     - amount: a formatted string, preferably converted using `localize(_:in:with:including:)`.
    ///     - position: the currency position enum, either right, left, right_space, or left_space.
    ///     - symbol: the currency symbol as a string, to be used with the amount.
    ///
    func formatCurrency(using amount: String, at position: CurrencySettings.CurrencyPosition, with symbol: String) -> String {
        let space = "\u{00a0}" // unicode equivalent of &nbsp;
        switch position {
        case .left:
            return symbol + amount
        case .right:
            return amount + symbol
        case .leftSpace:
            return symbol + space + amount
        case .rightSpace:
            return amount + space + symbol
        }
    }

    /// Applies currency option settings to the amount for the given currency.
    ///
    /// - Parameters:
    ///     - amount: a raw string representation of the amount, from the API, with no formatting applied. e.g. "19.87"
    ///     - currency: a 3-letter country code for currencies that are supported in the API. e.g. "USD"
    ///
    func formatAmount(_ amount: String, with currency: String = CurrencySettings.shared.currencyCode.rawValue) -> String? {
        guard let decimalAmount = convertToDecimal(from: amount) else {
            return nil
        }

        return formatAmount(decimalAmount, with: currency)
    }


    /// Formats the provided `amount` param into a human readable value and applies the currency option
    /// settings for the given currency.
    ///
    /// - Parameters:
    ///   - amount: a raw string representation of the amount, from the API, with no formatting applied. e.g. "19.87"
    ///   - currency: a 3-letter country code for currencies that are supported in the API. e.g. "USD"
    ///   - roundSmallNumbers: if `true`, small numbers are rounded, if `false`, no rounding occurs (defaults to true)
    /// - Returns: a formatted amount string
    ///
    /// For our purposes here, a "small number" is anything in-between -1000 and 1000 (exclusive).
    ///
    /// - Note: This func leverages the formatter from our `NSDecimalNumber` extension.
    ///         See: `NSDecimalNumber+Helpers.swift` for more details.
    ///
    /// Examples with currency code of "USD" (`roundSmallNumbers` is set to `true`):
    ///  - 0 becomes "$0"
    ///  - 198.44 becomes "$198"
    ///  - 198.88 becomes "$198"
    ///  - 999 becomes "$999"
    ///  - 1000 becomes "$1.0k"
    ///  - 5800199.56 becomes "$5.8m"
    ///
    /// Examples with currency code of "USD" (`roundSmallNumbers` is set to `false`):
    ///  - 0 becomes "$0.00"
    ///  - 198.44 becomes "$198.44"
    ///  - 198.88 becomes "$198.88"
    ///  - 999 becomes "$999.00"
    ///  - 1000 becomes "$1.0k"
    ///  - 5800199.56 becomes "$5.8m"
    ///
    func formatHumanReadableAmount(_ amount: String,
                                   with currency: String = CurrencySettings.shared.currencyCode.rawValue,
                                   roundSmallNumbers: Bool = true) -> String? {
        guard let decimalAmount = convertToDecimal(from: amount) else {
            return nil
        }

        let humanReadableAmount = decimalAmount.humanReadableString(roundSmallNumbers: roundSmallNumbers)
        if humanReadableAmount == decimalAmount.stringValue, roundSmallNumbers == false {
            // The human readable version of amount is the same as the converted param value which means this is a "small"
            // number — format it normally *without* rounding.
            return formatAmount(decimalAmount, with: currency)
        }

        // If we are here, the human readable version of the amount param is a "large" number *OR* a small number but rounding has been requested,
        // so let's just put the currency symbol on the correct side of the string with proper spacing (based on the site settings).
        let code = CurrencySettings.CurrencyCode(rawValue: currency) ?? CurrencySettings.shared.currencyCode
        let symbol = CurrencySettings.shared.symbol(from: code)
        return formatCurrency(using: humanReadableAmount, at: CurrencySettings.shared.currencyPosition, with: symbol)
    }

    /// Applies currency option settings to the amount for the given currency.
    /// - Parameters:
    ///     - amount: a NSDecimalNumber representation of the amount, from the API, with no formatting applied. e.g. "19.87"
    ///     - currency: a 3-letter country code for currencies that are supported in the API. e.g. "USD"
    ///
    func formatAmount(_ decimalAmount: NSDecimalNumber, with currency: String = CurrencySettings.shared.currencyCode.rawValue) -> String? {
        // Grab the read-only currency options. These are set by the user in Site > Settings.
        let separator = CurrencySettings.shared.decimalSeparator
        let position = CurrencySettings.shared.numberOfDecimals
        let thousandSeparator = CurrencySettings.shared.thousandSeparator

        let localized = localize(decimalAmount, with: separator, in: position, including: thousandSeparator)

        guard let localizedAmount = localized else {
            return nil
        }

        // If no country code was specified or it was not found, assume the user wants to use the default.
        let code = CurrencySettings.CurrencyCode(rawValue: currency) ?? CurrencySettings.shared.currencyCode
        let currencySymbol = CurrencySettings.shared.symbol(from: code)
        let currencyPosition = CurrencySettings.shared.currencyPosition
        let formattedAmount = formatCurrency(using: localizedAmount, at: currencyPosition, with: currencySymbol)

        return formattedAmount
    }
}

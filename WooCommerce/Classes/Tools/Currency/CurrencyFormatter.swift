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

        return numberFormatter.string(from: decimalAmount)
    }

    /// Returns a string that displays the amount using all of the specified currency settings
    /// - Parameters:
    ///     - amount: a formatted string, preferably converted using `localize(_:in:with:including:)`.
    ///     - position: the currency position enum, either right, left, right_space, or left_space.
    ///     - symbol: the currency symbol as a string, to be used with the amount.
    ///
    func formatCurrency(using amount: String, at position: Currency.Position, with symbol: String) -> String {
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

    /// Pull it all together! Applies currency option settings to the amount for the given currency.
    /// - Parameters:
    ///     - amount: a raw string representation of the amount, from the API, with no formatting applied. e.g. "19.87"
    ///     - currency: a 3-letter country code for currencies that are supported in the API. e.g. "USD"
    ///
    func formatAmount(_ amount: String, with currency: String = CurrencySettings.shared.currencyCode.rawValue) -> String? {
        guard let decimalAmount = convertToDecimal(from: amount) else {
            return nil
        }

        // Grab the read-only currency options. These are set by the user in Site > Settings.
        let separator = Currency.decimalSeparator
        let position = Currency.decimalPosition
        let thousandSeparator = Currency.thousandSeparator

        let localized = localize(decimalAmount, with: separator, in: position, including: thousandSeparator)

        guard let localizedAmount = localized else {
            return nil
        }

        // If no country code was specified or it was not found, assume the user wants to use the default.
        let code = Currency.Code(rawValue: currency) ?? Currency.code
        let currencySymbol = Currency.symbol(from: code)
        let currencyPosition = Currency.position
        let formattedAmount = formatCurrency(using: localizedAmount, at: currencyPosition, with: currencySymbol)

        return formattedAmount
    }
}

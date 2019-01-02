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

        let stringResult = numberFormatter.string(from: decimalAmount)

        return stringResult
    }

    /// Returns a string that displays the amount using all of the specified currency settings
    /// - Parameters:
    ///     - localizedAmount: a formatted string returned from `localizeAmount()`
    ///     - currencyPosition: the currency position, either right, left, right_space, or left_space.
    ///     - currencyCode: the three-letter country code used for a currency, e.g. CAD.
    func formatCurrency(using amount: String, at position: Currency.Position, with symbol: String) -> String? {
        switch position {
        case .left:
            return symbol + amount
        case .right:
            return amount + symbol
        case .leftSpace:
            return symbol + "\u{00a0}" + amount
        case .rightSpace:
            return amount + "\u{00a0}" + symbol
        }
    }

    /// Pull it all together! Applies currency option settings to the amount for the given currency.
    /// - Parameters:
    ///     - amount: a raw string representation of the amount, from the API, with no formatting applied. e.g. "19.87"
    ///     - currency: a 3-letter country code for currencies that are supported in the API. e.g. "USD"
    func formatAmount(_ amount: String, with currency: String = CurrencySettings.shared.currencyCode.rawValue) -> String? {
        guard let decimalAmount = convertToDecimal(from: amount) else {
            return nil
        }

        // Grab the read-only currency options. These are set by the user in Site > Settings.
        let separator = Currency().decimalSeparator
        let position = Currency().decimalPosition
        let thousandSeparator = Currency().thousandSeparator

        let localized = localize(decimalAmount, with: separator, in: position, including: thousandSeparator)

        guard let localizedAmount = localized else {
            return nil
        }

        // If no country code was specified or it was not found, assume the user wants to use the default.
        let code = Currency.Code(rawValue: currency) ?? Currency().code
        let currencySymbol = Currency().symbol(from: code)
        let currencyPosition = Currency().position
        let formattedAmount = formatCurrency(using: localizedAmount, at: currencyPosition, with: currencySymbol)

        return formattedAmount
    }

    // MARK: - Helper methods

    func stringFormatIsValid(_ stringValue: String, for decimalPlaces: Int = 2) -> Bool {
        guard stringValue.characterCount >= 4 else {
            DDLogError("Error: this method expects a string with a minimum of 4 characters.")
            return false
        }

        let decimalIndex = stringValue.characterCount - decimalPlaces
        var containsDecimal = false

        for (index, char) in stringValue.enumerated() {
            if index == decimalIndex && char == "." {
                containsDecimal = true
                break
            }
        }

        guard containsDecimal else {
            DDLogError("Error: this method expects a decimal notation from the string parameter.")
            return false
        }

        return true
    }
}


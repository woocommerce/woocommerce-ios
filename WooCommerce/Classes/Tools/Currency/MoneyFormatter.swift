import Foundation

public class MoneyFormatter {

    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currency

        return formatter
    }()


    /// Returns a localized and formatted currency string, including zero values.
    ///
    func format(value: String, currencyCode: String, locale: Locale = .current) -> String? {
        guard let decimal = Decimal(string: value) else {
            return nil
        }

        return format(value: decimal, currencyCode: currencyCode, locale: locale)
    }

    /// Returns a localized and formatted currency string, including zero values.
    ///
    func format(value: Decimal, currencyCode: String, locale: Locale = .current) -> String? {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode
        let decimalNumber = NSDecimalNumber(decimal: value)

        return currencyFormatter.string(from: decimalNumber)
    }

    /// Returns a localized and formatted currency string, or nil if empty or zero.
    ///
    func formatIfNonZero(value: String, currencyCode: String, locale: Locale = .current) -> String? {
        guard value.isEmpty == false else {
            return nil
        }

        guard let decimal = Decimal(string: value) else {
            return nil
        }

        return formatIfNonZero(value: decimal,
                               currencyCode: currencyCode,
                               locale: locale)
    }

    /// Returns a localized and formatted currency string, or nil if value is zero.
    ///
    func formatIfNonZero(value: Decimal, currencyCode: String, locale: Locale = .current) -> String? {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode

        if value.isZero {
            return nil
        }

        let decimalNumber = NSDecimalNumber(decimal: value)

        return currencyFormatter.string(from: decimalNumber)
    }

    /// Returns the symbol only, no formatting applied.
    ///
    func currencySymbol(currencyCode: String, locale: Locale = .current) -> String? {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode

        return currencyFormatter.currencySymbol
    }
}


// MARK: - Manual currency formatting
//
extension MoneyFormatter {
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
    func localizeAmount(decimal: NSDecimalNumber, decimalSeparator: String? = ".", decimalPosition: Int = 2, thousandSeparator: String? = ",") -> String? {
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

        let stringResult = numberFormatter.string(from: decimal)

        return stringResult
    }

    /// Returns a string that displays the amount using all of the specified currency settings
    /// - Parameters:
    ///     - localizedAmount: a formatted string returned from `localizeAmount()`
    ///     - currencyPosition: the currency position, either right, left, right_space, or left_space.
    ///     - currencyCode: the three-letter country code used for a currency, e.g. CAD.
    func formatCurrency(using amount: String,
                        at position: Currency.Position,
                        with code: Currency.Code) -> String? {
        let currency = Currency(amount: amount, code: code, position: position)
        let symbol = currency.symbol

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
                break;
            }
        }

        guard containsDecimal else {
            DDLogError("Error: this method expects a decimal notation from the string parameter.")
            return false
        }

        return true
    }
}

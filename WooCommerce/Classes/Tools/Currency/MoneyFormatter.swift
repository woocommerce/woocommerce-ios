import Foundation

public class MoneyFormatter {

    private lazy var currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currency

        return formatter
    }()


    /// Returns a formatted decimal value from a given string.
    ///
    func formatDecimal(from stringValue: String) -> Decimal? {
        guard let decimalValue = Decimal(string: stringValue) else {
            DDLogError("Error: string value could not be converted to decimal: \(stringValue)")
            return nil
        }

        return decimalValue
    }

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

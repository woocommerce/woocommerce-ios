import Foundation

public struct MoneyFormatter {

    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.usesGroupingSeparator = true
        formatter.numberStyle = .currencyISOCode

        return formatter
    }

    /// Returns a localized and formatted currency string, including zero values.
    ///
    func format(value: String, currencyCode: String, locale: Locale = Locale.current) -> String {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode
        let decimalValue = Decimal(string: value) ?? Decimal(string: "0.0")

        guard let decimal = decimalValue else {
            fatalError("A default localized currency value should be returned, e.g.: $0.00")
        }

        let decimalNumber = NSDecimalNumber(decimal: decimal)
        guard let numberValue = currencyFormatter.string(from: decimalNumber) else {
            fatalError()
        }

        return numberValue
    }

    /// Returns a localized and formatted currency string, including zero values.
    ///
    func format(value: Decimal, currencyCode: String, locale: Locale = Locale.current) -> String {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode
        let decimalNumber = NSDecimalNumber(decimal: value)
        guard let numberValue = currencyFormatter.string(from: decimalNumber) else {
            fatalError()
        }

        return numberValue
    }

    /// Returns a localized and formatted currency string, or nil if empty or zero.
    ///
    func formatIfNonZero(value: String, currencyCode: String, locale: Locale = Locale.current) -> String? {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode
        guard value.isEmpty == false else {
            return nil
        }
        currencyFormatter.currencyCode = currencyCode

        let decimalNumber = NSDecimalNumber(string: value)
        if decimalNumber.decimalValue.isZero {
            return nil
        }

        return currencyFormatter.string(from: decimalNumber)
    }

    /// Returns a localized and formatted currency string, or nil if value is zero.
    ///
    func formatIfNonZero(value: Decimal, currencyCode: String, locale: Locale = Locale.current) -> String? {
        currencyFormatter.locale = locale
        currencyFormatter.currencyCode = currencyCode
        let decimalNumber = NSDecimalNumber(decimal: value)
        if decimalNumber.decimalValue.isZero {
            return nil
        }

        return currencyFormatter.string(from: decimalNumber)
    }
}

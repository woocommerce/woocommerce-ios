import Foundation

struct MoneyFormatter {

    /// Returns a localized and formatted currency string, including zero values.
    ///
    func format(value: String, currencyCode: String) -> String {
        let formatter = currencyFormatter(currencyCode: currencyCode)
        let decimalValue = Decimal(string: value) ?? Decimal(string: "0.0")

        guard let decimal = decimalValue else {
            fatalError("A default localized currency value should be returned, e.g.: $0.00")
        }

        let decimalNumber = NSDecimalNumber(decimal: decimal)
        guard let numberValue = formatter.string(from: decimalNumber) else {
            fatalError()
        }

        return numberValue
    }

    /// Returns a localized and formatted currency string, including zero values.
    ///
    func format(value: Decimal, currencyCode: String) -> String {
        let formatter = currencyFormatter(currencyCode: currencyCode)
        let decimalNumber = NSDecimalNumber(decimal: value)
        guard let numberValue = formatter.string(from: decimalNumber) else {
            fatalError()
        }

        return numberValue
    }

    /// Returns a localized and formatted currency string, or nil if empty or zero.
    ///
    func formatIfNonZero(value: String, currencyCode: String) -> String? {
        guard value.isEmpty == false else {
            return nil
        }

        let decimalNumber = NSDecimalNumber(string: value)
        if decimalNumber.decimalValue.isZero {
            return nil
        }

        let formatter = currencyFormatter(currencyCode: currencyCode)

        return formatter.string(from: decimalNumber)
    }

    /// Returns a localized and formatted currency string, or nil if value is zero.
    ///
    func formatIfNonZero(value: Decimal, currencyCode: String) -> String? {
        let decimalNumber = NSDecimalNumber(decimal: value)
        if decimalNumber.decimalValue.isZero {
            return nil
        }

        let formatter = currencyFormatter(currencyCode: currencyCode)

        return formatter.string(from: decimalNumber)
    }

    /// Returns a currency formatter instance based on ISO 4217 currency codes.
    ///
    func currencyFormatter(currencyCode: String) -> NumberFormatter {
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currencyISOCode
        currencyFormatter.locale = Locale.current
        currencyFormatter.currencyCode = currencyCode

        return currencyFormatter
    }
}

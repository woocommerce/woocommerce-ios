import Foundation

extension NumberFormatter {
    /// Get a double from a string value, with locale taken into consideration.
    ///
    static func double(from string: String, locale: Locale = .current) -> Double? {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        formatter.roundingMode = .halfUp
        let number = formatter.number(from: string)
        return number?.doubleValue
    }

    /// Get a string from a number with locale taken into consideration.
    ///
    static func localizedString(from number: NSNumber, locale: Locale = .current) -> String? {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.usesGroupingSeparator = true
        formatter.groupingSize = 3
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        formatter.roundingMode = .halfUp
        return formatter.string(from: number)
    }
}

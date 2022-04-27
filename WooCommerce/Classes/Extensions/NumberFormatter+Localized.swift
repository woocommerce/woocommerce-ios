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

    /// Converts given number in string format, from the specified source locale to target locale.
    ///
    /// This method does not accept numbers with grouping separator. (No thousands separator)
    ///
    /// - Parameters:
    ///     - using: The string to be localized.
    ///     - from: The current `Locale` of the input string.
    ///     - to: The `Locale` to be used for localizing the input string.
    ///
    /// - Returns: The input string localized to the target locale. Returns `nil` if the localization is unsucessful.
    ///
    static func localizedString(using string: String,
                                from sourceLocale: Locale,
                                to targetLocale: Locale) -> String? {
        let formatter = NumberFormatter()
        formatter.locale = sourceLocale
        formatter.usesGroupingSeparator = false
        formatter.formatterBehavior = .behavior10_4
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        formatter.roundingMode = .halfUp

        guard let number = formatter.number(from: string) else {
            return nil
        }

        formatter.locale = targetLocale

        return formatter.string(from: number)
    }
}

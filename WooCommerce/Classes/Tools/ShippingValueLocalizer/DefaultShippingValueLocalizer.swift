import Foundation

/// Default implementation for `ShippingValueLocalizer`
///
/// Localizes the shipping value between device locale and API preferred locale (US locale)
///
///
struct DefaultShippingValueLocalizer: ShippingValueLocalizer {

    // Device locale.
    //
    private let deviceLocale: Locale

    // API preferred locale.
    //
    private let apiLocale: Locale

    init(deviceLocale: Locale = .current,
        apiLocale: Locale = Locale(identifier: "en_US") // API uses US locale for weight and shipping dimensions
    ) {
        self.deviceLocale = deviceLocale
        self.apiLocale = apiLocale
    }

    /// Localizes the shipping value from `apiLocale` to `deviceLocale`
    ///
    /// Returns `nil` for numbers with grouping separator. (No thousands separator)
    ///
    /// Because, API does not support having thousand separators in shipping values like weight and package dimensions.
    ///
    func localized(shippingValue: String?) -> String? {
        guard let shippingValue = shippingValue else {
            return nil
        }
        return localizedString(using: shippingValue, from: apiLocale, to: deviceLocale)
    }

    /// Localizes the shipping value from `deviceLocale` to `apiLocale`
    ///
    /// Returns `nil` for numbers with grouping separator. (No thousands separator)
    ///
    /// Because, API does not support having thousand separators in shipping values like weight and package dimensions.
    ///
    func unLocalized(shippingValue: String?) -> String? {
        guard let shippingValue = shippingValue else {
            return nil
        }
        return localizedString(using: shippingValue, from: deviceLocale, to: apiLocale)
    }
}

private extension DefaultShippingValueLocalizer {
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
    func localizedString(using string: String,
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

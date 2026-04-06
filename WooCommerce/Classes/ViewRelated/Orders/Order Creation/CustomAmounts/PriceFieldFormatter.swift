import Foundation
import WooFoundation

class PriceFieldFormatter {

    /// Formatted amount to display. When empty displays a placeholder value.
    ///
    var formattedAmount: String {
        guard amount.isNotEmpty else {
            return amountPlaceholder
        }
        return amountWithSymbol
    }

    /// Current amount converted to Decimal.
    ///
    var amountDecimal: Decimal {
        guard amount.isNotEmpty else { return .zero }
        let storeDecimalSeparator = storeCurrencySettings.sanitizedDecimalSeparator
        let normalizedAmount = amount.replacingOccurrences(of: storeDecimalSeparator, with: ".")
        guard let decimal = Decimal(string: normalizedAmount) else {
            DDLogError("Failed to convert amount to Decimal: \(amount)")
            return .zero
        }
        return decimal
    }

    /// Duplicates input var for internal reference
    ///
    private var amount: String = ""

    /// Stores the formatted amount with the store currency symbol.
    ///
    private var amountWithSymbol: String = ""

    /// Dynamically builds the amount placeholder based on the store decimal separator.
    ///
    private lazy var amountPlaceholder: String = {
        currencyFormatter.formatAmount("0.00") ?? "$0.00"
    }()

    /// Users locale, needed to use the correct decimal separator
    ///
    private let userLocale: Locale

    /// Current store currency settings
    ///
    private let storeCurrencySettings: CurrencySettings

    /// Currency formatter for the provided amount
    ///
    private let currencyFormatter: CurrencyFormatter

    /// Setting to allow negative number input
    ///
    private let allowNegativeNumber: Bool

    private let minusSign: String = NumberFormatter().minusSign

    private let sanitizer: CurrencyInputSanitizer

    init(locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         allowNegativeNumber: Bool = false) {
        self.userLocale = locale
        self.storeCurrencySettings = storeCurrencySettings
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        self.allowNegativeNumber = allowNegativeNumber
        self.sanitizer = CurrencyInputSanitizer(
            currencySettings: storeCurrencySettings,
            deviceDecimalSeparator: locale.decimalSeparator
        )
    }

    /// Formats user input by removing non-numeric symbols, thousands separator, and using store's currency settings.
    ///
    /// Input is assumed to be in device's locale, mainly to support decimal separator input with
    /// iOS keyboard which shows localized separators.
    /// If store and device have inverse thousand and decimal separators, a correct conversion
    /// would only be done for device-supported input.
    /// See PriceFieldFormatterTests for more examples.
    ///
    /// - Parameter userInput: An amount user has entered into a text field
    /// - Returns: A sanitized and formatted amount
    func formatUserInput(_ userInput: String) -> String {
        let sanitizedInput = sanitizeUserInput(userInput)
        amount = formatSanitizedAmount(sanitizedInput)
        amountWithSymbol = setCurrencySymbol(to: amount)
        return amount
    }

    /// Formats user input without thousands separator using store's currency settings
    ///
    func formatAmount(_ decimal: Decimal) -> String {
        amount = formatSanitizedAmount(sanitizer.formatDecimal(decimal))
        amountWithSymbol = setCurrencySymbol(to: amount)
        return amount
    }
}

// MARK: Helpers
private extension PriceFieldFormatter {
    /// Sanitizes user input assuming amount is entered using device settings over store settings
    ///
    func sanitizeUserInput(_ amount: String) -> String {
        guard amount.isNotEmpty else { return amount }

        let negativePrefix = allowNegativeNumber && amount.hasPrefix(minusSign) ? minusSign : ""
        let deviceDecimalSeparator = userLocale.decimalSeparator ?? "."
        let storeDecimalSeparator = storeCurrencySettings.sanitizedDecimalSeparator

        // Removes any unwanted character & makes sure to use the store decimal separator
        let sanitized = amount
            .replacingOccurrences(of: deviceDecimalSeparator, with: storeDecimalSeparator)
            .filter { $0.isNumber || "\($0)" == storeDecimalSeparator }

        return negativePrefix + sanitized
    }

    /// Formats a received sanitized value by trimming content to the allowed number of decimal places.
    ///
    func formatSanitizedAmount(_ amount: String) -> String {
        let storeDecimalSeparator = storeCurrencySettings.sanitizedDecimalSeparator
        let storeNumberOfDecimals = storeCurrencySettings.fractionDigits

        let components = amount.components(separatedBy: storeDecimalSeparator)
        switch components.count {
        case 1 where amount.contains(storeDecimalSeparator):
            return components[0] + storeDecimalSeparator
        case 1:
            return components[0]
        case 2...Int.max:
            let number = components[0]
            let decimals = components[1]
            let trimmedDecimals = decimals.count > storeNumberOfDecimals ? "\(decimals.prefix(storeNumberOfDecimals))" : decimals
            return number + storeDecimalSeparator + trimmedDecimals
        default:
            fatalError("Should not happen, components can't be 0 or negative")
        }
    }

    /// Formats a received value by adding the store currency symbol to its correct position.
    ///
    func setCurrencySymbol(to amount: String) -> String {
        sanitizer.addCurrencySymbol(to: amount, isNegative: allowNegativeNumber && amount.hasPrefix(minusSign))
    }
}

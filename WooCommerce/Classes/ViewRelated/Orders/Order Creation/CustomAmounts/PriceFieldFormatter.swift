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
        guard let decimal = decimalFormatter.number(from: amount)?.decimalValue else {
            if amount.isNotEmpty {
                DDLogError("Failed to convert amount to Decimal: \(amount)")
            }
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

    /// Current store currency symbol
    ///
    private let storeCurrencySymbol: String

    /// Setting to allow negative number input
    ///
    private let allowNegativeNumber: Bool

    private let minusSign: String = NumberFormatter().minusSign

    /// Price Field number formatter with store decimal separator without thousands separator
    ///
    private lazy var decimalFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.decimalSeparator = storeCurrencySettings.sanitizedDecimalSeparator
        formatter.maximumFractionDigits = storeCurrencySettings.fractionDigits
        formatter.minimumFractionDigits = storeCurrencySettings.fractionDigits
        formatter.usesGroupingSeparator = false
        formatter.numberStyle = .decimal
        return formatter
    }()

    init(locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         allowNegativeNumber: Bool = false) {
        self.userLocale = locale
        self.storeCurrencySettings = storeCurrencySettings
        self.storeCurrencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        self.allowNegativeNumber = allowNegativeNumber
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
        amount = formatSanitizedAmount(decimalFormatter.string(from: decimal as NSNumber) ?? decimal.formatted())
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

    /// Formats a received sanitized value by trimming content to two decimal places.
    ///
    func formatSanitizedAmount(_ amount: String) -> String {
        // Trim to two decimals & remove any extra "."
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

    /// Formats a received value by adding the store currency symbol to it's correct position.
    ///
    func setCurrencySymbol(to amount: String) -> String {
        currencyFormatter.formatCurrency(using: amount,
                                         currencyPosition: storeCurrencySettings.currencyPosition,
                                         currencySymbol: storeCurrencySymbol,
                                         isNegative: allowNegativeNumber && amount.hasPrefix(minusSign))
    }
}

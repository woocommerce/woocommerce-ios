import Foundation

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
    var amountDecimal: Decimal? {
        guard let amountDecimal = currencyFormatter.convertToDecimal(from: amount) else {
            return nil
        }

        return amountDecimal as Decimal
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

    init(locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         allowNegativeNumber: Bool = false) {
        self.userLocale = locale
        self.storeCurrencySettings = storeCurrencySettings
        self.storeCurrencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        self.allowNegativeNumber = allowNegativeNumber
    }

    func formatAmount(_ updatedAmount: String) -> String {
        amount = sanitizeAmount(updatedAmount)
        amountWithSymbol = setCurrencySymbol(to: amount)
        return amount
    }
}

// MARK: Helpers
private extension PriceFieldFormatter {

    /// Formats a received value by sanitizing the input and trimming content to two decimal places.
    ///
    func sanitizeAmount(_ amount: String) -> String {
        guard amount.isNotEmpty else { return amount }

        let negativePrefix = allowNegativeNumber && amount.hasPrefix(minusSign) ? minusSign : ""

        let deviceDecimalSeparator = userLocale.decimalSeparator ?? "."
        let storeDecimalSeparator = storeCurrencySettings.decimalSeparator
        let storeNumberOfDecimals = storeCurrencySettings.numberOfDecimals

        // Removes any unwanted character & makes sure to use the store decimal separator
        let sanitized = amount
            .replacingOccurrences(of: deviceDecimalSeparator, with: storeDecimalSeparator)
            .filter { $0.isNumber || "\($0)" == storeDecimalSeparator }

        // Trim to two decimals & remove any extra "."
        let components = sanitized.components(separatedBy: storeDecimalSeparator)
        switch components.count {
        case 1 where sanitized.contains(storeDecimalSeparator):
            return negativePrefix + components[0] + storeDecimalSeparator
        case 1:
            return negativePrefix + components[0]
        case 2...Int.max:
            let number = components[0]
            let decimals = components[1]
            let trimmedDecimals = decimals.count > storeNumberOfDecimals ? "\(decimals.prefix(storeNumberOfDecimals))" : decimals
            return negativePrefix + number + storeDecimalSeparator + trimmedDecimals
        default:
            fatalError("Should not happen, components can't be 0 or negative")
        }
    }

    /// Formats a received value by adding the store currency symbol to it's correct position.
    ///
    func setCurrencySymbol(to amount: String) -> String {
        currencyFormatter.formatCurrency(using: amount,
                                         at: storeCurrencySettings.currencyPosition,
                                         with: storeCurrencySymbol,
                                         isNegative: allowNegativeNumber && amount.hasPrefix(minusSign))
    }
}

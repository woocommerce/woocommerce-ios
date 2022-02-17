import SwiftUI
import struct Yosemite.ShippingLine

class ShippingLineDetailsViewModel: ObservableObject {

    /// Closure to be invoked when the shipping line is updated.
    ///
    var didSelectSave: ((ShippingLine?) -> Void)

    /// Stores the amount(unformatted) entered by the merchant.
    ///
    @Published var amount: String = "" {
        didSet {
            guard amount != oldValue else { return }
            amount = sanitizeAmount(amount)
            amountWithSymbol = setCurrencySymbol(to: amount)
        }
    }

    /// Stores the method title entered by the merchant.
    ///
    @Published var methodTitle: String

    private let initialAmount: NSDecimalNumber
    private let initialMethodTitle: String

    /// Returns true when existing shipping line is edited.
    ///
    let isExistingShippingLine: Bool

    /// Formatted amount to display. When empty displays a placeholder value.
    ///
    var formattedAmount: String {
        guard amount.isNotEmpty else {
            return amountPlaceholder
        }
        return amountWithSymbol
    }

    /// Defines the amount text color.
    ///
    var amountTextColor: UIColor {
        amount.isEmpty ? .textSubtle : .text
    }

    /// Stores the formatted amount with the store currency symbol.
    ///
    private var amountWithSymbol: String = ""

    /// Dynamically builds the amount placeholder based on the store decimal separator.
    ///
    private lazy var amountPlaceholder: String = {
        currencyFormatter.formatAmount("0.00") ?? "$0.00"
    }()

    /// Method title entered by user or placeholder if it's empty.
    ///
    private var finalMethodTitle: String {
        methodTitle.isNotEmpty ? methodTitle : Localization.namePlaceholder
    }

    /// Returns true when there are no valid pending changes.
    ///
    var shouldDisableDoneButton: Bool {
        guard let amountDecimal = currencyFormatter.convertToDecimal(from: amount), amountDecimal as Decimal > 0 else {
            return true
        }

        let amountUpdated = amountDecimal != initialAmount
        let methodTitleUpdated = finalMethodTitle != initialMethodTitle

        return !(amountUpdated || methodTitleUpdated)
    }

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

    init(inputData: NewOrderViewModel.PaymentDataViewModel,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         didSelectSave: @escaping ((ShippingLine?) -> Void)) {
        self.userLocale = locale
        self.storeCurrencySettings = storeCurrencySettings
        self.storeCurrencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        self.didSelectSave = didSelectSave

        self.isExistingShippingLine = inputData.shouldShowShippingTotal
        self.initialMethodTitle = inputData.shippingMethodTitle
        self.methodTitle = initialMethodTitle

        self.initialAmount = currencyFormatter.convertToDecimal(from: inputData.shippingTotal) ?? .zero
        if initialAmount as Decimal > 0, let formattedAmount = currencyFormatter.formatAmount(initialAmount) {
            self.amount = formattedAmount
        }
    }

    func saveData() {
        let shippingLine = ShippingLine(shippingID: 0,
                                        methodTitle: finalMethodTitle,
                                        methodID: "other",
                                        total: amount,
                                        totalTax: "",
                                        taxes: [])
        didSelectSave(shippingLine)
    }
}
// MARK: Helpers
private extension ShippingLineDetailsViewModel {
    /// Formats a received value by sanitizing the input and trimming content to two decimal places.
    ///
    func sanitizeAmount(_ amount: String) -> String {
        guard amount.isNotEmpty else { return amount }

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
                                         at: storeCurrencySettings.currencyPosition,
                                         with: storeCurrencySymbol,
                                         isNegative: false)
    }
}

// MARK: Constants

extension ShippingLineDetailsViewModel {
    enum Localization {
        static let namePlaceholder = NSLocalizedString("Shipping",
                                                       comment: "Placeholder for the name field on the Shipping Line Details screen during order creation")
    }
}

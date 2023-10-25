import SwiftUI
import Yosemite
import WooFoundation

protocol FeeOrDiscountLineTypeProtocol {
    var navigationTitle: String { get }
    var removeButtonTitle: String { get }
    var doneButtonAccessibilityIdentifier: String { get }
    var fixedAmountFieldAccessibilityIdentifier: String { get }

    func removeEvent() -> WooAnalyticsEvent?
}

private struct StringsProviderFactory {
    static func typeViewModel(from type: LegacyFeeOrDiscountLineDetailsViewModel.LineType, isExistingLine: Bool) -> FeeOrDiscountLineTypeProtocol {
        switch type {
        case .discount:
            return DiscountLineTypeViewModel(isExistingLine: isExistingLine)
        case .fee:
            return FeeLineTypeViewModel(isExistingLine: isExistingLine)
        }
    }
}

final class LegacyFeeOrDiscountLineDetailsViewModel: ObservableObject {

    /// Closure to be invoked when the line is updated.
    ///
    private let didSelectSave: ((String?) -> Void)

    /// Helper to format price field input.
    ///
    private let priceFieldFormatter: PriceFieldFormatter

    /// Stores the fixed amount entered by the merchant.
    ///
    @Published var amount: String = "" {
        didSet {
            guard amount != oldValue else { return }
            amount = priceFieldFormatter.formatAmount(amount)
        }
    }

    /// Stores the percentage entered by the merchant.
    ///
    @Published var percentage: String = "" {
        didSet {
            guard percentage != oldValue else { return }
            percentage = sanitizePercentageAmount(percentage)
        }
    }

    /// Returns true when a discount is entered, either fixed or percentage.
    ///
    var hasInputAmount: Bool {
        amount.isNotEmpty || percentage.isNotEmpty
    }

    /// Decimal value of currently entered fee or discount. For percentage type it is calculated final amount.
    ///
    private var finalAmountDecimal: Decimal {
        let inputString = discountType == .fixed ? amount : percentage
        guard let decimalInput = currencyFormatter.convertToDecimal(inputString) else {
            return .zero
        }

        switch discountType {
        case .fixed:
            return decimalInput as Decimal
        case .percentage:
            return baseAmountForPercentage * (decimalInput as Decimal) * 0.01
        }
    }

    /// Formatted string value of currently entered fee or discount. For percentage type it is calculated final amount.
    ///
    var finalAmountString: String? {
        currencyFormatter.formatAmount(finalAmountDecimal)
    }

    /// Returns the formatted string value of a price, substracting the current stored discount entered by the merchant
    ///
    func calculatePriceAfterDiscount(_ price: String) -> String {
        guard let price = currencyFormatter.convertToDecimal(price),
              let discount = currencyFormatter.convertToDecimal(finalAmountString ?? "") else {
            return ""
        }
        let priceAfterDiscount = price.subtracting(discount)
        return currencyFormatter.formatAmount(priceAfterDiscount) ?? ""
    }

    /// The base amount to apply percentage fee or discount on.
    ///
    private let baseAmountForPercentage: Decimal

    /// The initial fee or discount amount.
    ///
    private let initialAmount: Decimal

    /// Returns true when existing line is edited.
    ///
    let isExistingLine: Bool

    /// Returns true when base amount for percentage > 0.
    ///
    var isPercentageOptionAvailable: Bool {
        !isExistingLine && baseAmountForPercentage > 0
    }

    /// Returns true when there are no valid pending changes.
    ///
    var shouldDisableDoneButton: Bool {
        guard finalAmountDecimal != .zero else {
            return true
        }

        return finalAmountDecimal == initialAmount
    }

    let lineTypeViewModel: FeeOrDiscountLineTypeProtocol

    /// Localized percent symbol.
    ///
    let percentSymbol: String

    /// Current store currency symbol.
    ///
    let currencySymbol: String

    /// Position for currency symbol, relative to amount text field.
    ///
    let currencyPosition: CurrencySettings.CurrencyPosition

    /// Currency formatter setup with store settings.
    ///
    private let currencyFormatter: CurrencyFormatter

    private let minusSign: String = NumberFormatter().minusSign

    /// Analytics engine.
    ///
    private let analytics: Analytics

    /// Placeholder for amount text field.
    ///
    let amountPlaceholder: String

    enum LineType {
        case fee
        case discount
    }

    enum DiscountType: String {
        case fixed
        case percentage
    }

    @Published var discountType: DiscountType = .fixed

    init(isExistingLine: Bool,
         baseAmountForPercentage: Decimal,
         initialTotal: String,
         lineType: LineType,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         didSelectSave: @escaping ((String?) -> Void)) {
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings, allowNegativeNumber: true)
        self.percentSymbol = NumberFormatter().percentSymbol
        self.currencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.currencyPosition = storeCurrencySettings.currencyPosition
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        self.amountPlaceholder = priceFieldFormatter.formatAmount("0")
        self.analytics = analytics

        self.isExistingLine = isExistingLine
        self.baseAmountForPercentage = baseAmountForPercentage

        if let initialAmount = currencyFormatter.convertToDecimal(initialTotal) {
            self.initialAmount = initialAmount as Decimal
        } else {
            self.initialAmount = .zero
        }

        if initialAmount != 0, let formattedInputAmount = currencyFormatter.formatAmount(initialAmount) {
            self.amount = priceFieldFormatter.formatAmount(formattedInputAmount)
            self.percentage = priceFieldFormatter.formatAmount("\(initialAmount / baseAmountForPercentage * 100)")
        }

        self.didSelectSave = didSelectSave
        self.lineTypeViewModel = StringsProviderFactory.typeViewModel(from: lineType, isExistingLine: isExistingLine)
    }

    func removeValue() {
        if let event = lineTypeViewModel.removeEvent() {
            analytics.track(event: event)
        }

        didSelectSave(nil)
    }

    func saveData() {
        guard let finalAmountString = finalAmountString else {
            return
        }

        didSelectSave(priceFieldFormatter.formatAmount(finalAmountString))
    }
}

private extension LegacyFeeOrDiscountLineDetailsViewModel {

    /// Formats a received value by sanitizing the input and trimming content to two decimal places.
    ///
    func sanitizePercentageAmount(_ amount: String) -> String {
        let deviceDecimalSeparator = Locale.autoupdatingCurrent.decimalSeparator ?? "."
        let numberOfDecimals = 2

        let negativePrefix = amount.hasPrefix(minusSign) ? minusSign : ""

        let sanitized = amount
            .filter { $0.isNumber || "\($0)" == deviceDecimalSeparator }

        // Trim to two decimals & remove any extra "."
        let components = sanitized.components(separatedBy: deviceDecimalSeparator)
        switch components.count {
        case 1 where sanitized.contains(deviceDecimalSeparator):
            return negativePrefix + components[0] + deviceDecimalSeparator
        case 1:
            return negativePrefix + components[0]
        case 2...Int.max:
            let number = components[0]
            let decimals = components[1]
            let trimmedDecimals = decimals.prefix(numberOfDecimals)
            return negativePrefix + number + deviceDecimalSeparator + trimmedDecimals
        default:
            fatalError("Should not happen, components can't be 0 or negative")
        }
    }
}

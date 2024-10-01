import SwiftUI
import Yosemite
import WooFoundation

protocol FeeOrDiscountLineTypeViewModel {
    var navigationTitle: String { get }
    var removeButtonTitle: String { get }
    var doneButtonAccessibilityIdentifier: String { get }
    var fixedAmountFieldAccessibilityIdentifier: String { get }

    func removeEvent() -> WooAnalyticsEvent?
    func addValueEvent(with type: FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType) -> WooAnalyticsEvent?
}

private struct StringsProviderFactory {
    static func typeViewModel(from type: FeeOrDiscountLineDetailsViewModel.LineType, isExistingLine: Bool) -> FeeOrDiscountLineTypeViewModel {
        switch type {
        case .discount:
            return DiscountLineTypeViewModel(isExistingLine: isExistingLine)
        case .fee:
            return FeeLineTypeViewModel(isExistingLine: isExistingLine)
        }
    }
}

private struct DiscountLineTypeViewModel: FeeOrDiscountLineTypeViewModel {
    let isExistingLine: Bool

    var navigationTitle: String {
        isExistingLine ? Localization.discount : Localization.addDiscount
    }

    var removeButtonTitle: String {
        Localization.remove
    }

    var doneButtonAccessibilityIdentifier: String {
        "add-discount-done-button"
    }

    var fixedAmountFieldAccessibilityIdentifier: String {
        "add-discount-fixed-amount-field"
    }

    func removeEvent() -> WooAnalyticsEvent? {
        WooAnalyticsEvent.Orders.productDiscountRemove()
    }

    func addValueEvent(with type: FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType) -> WooAnalyticsEvent? {
        WooAnalyticsEvent.Orders.productDiscountAdd(type: type)
    }

    private enum Localization {
        static let addDiscount = NSLocalizedString("Add Discount", comment: "Title for the Discount screen during order creation")
        static let discount = NSLocalizedString("Discount", comment: "Title for the Discount Details screen during order creation")
        static let remove = NSLocalizedString("Remove Discount", comment: "Title for the Remove button in Details screen during order creation")
    }
}

private struct FeeLineTypeViewModel: FeeOrDiscountLineTypeViewModel {
    let isExistingLine: Bool

    var navigationTitle: String {
        isExistingLine ? Localization.fee : Localization.addFee
    }

    var removeButtonTitle: String {
        Localization.remove
    }

    var doneButtonAccessibilityIdentifier: String {
        "add-fee-done-button"
    }

    var fixedAmountFieldAccessibilityIdentifier: String {
        "add-fee-fixed-amount-field"
    }

    func removeEvent() -> WooAnalyticsEvent? {
        nil
    }

    func addValueEvent(with type: FeeOrDiscountLineDetailsViewModel.FeeOrDiscountType) -> WooAnalyticsEvent? {
        nil
    }

    private enum Localization {
        static let addFee = NSLocalizedString("Add Fee", comment: "Title for the Fee screen during order creation")
        static let fee = NSLocalizedString("Fee", comment: "Title for the Fee Details screen during order creation")
        static let remove = NSLocalizedString("Remove Fee from Order",
                                              comment: "Text for the button to remove a fee from the order during order creation")
    }
}

final class FeeOrDiscountLineDetailsViewModel: ObservableObject {

    /// Closure to be invoked when the line is updated.
    ///
    private let didSelectSave: ((_ discount: Decimal?) -> Void)

    /// Helper to format price field input.
    ///
    private let priceFieldFormatter: PriceFieldFormatter
    private let percentageFieldFormatter: PriceFieldFormatter

    /// Stores the fixed amount entered by the merchant.
    ///
    @Published var amount: String = ""

    /// Stores the percentage entered by the merchant.
    ///
    @Published var percentage: String = ""

    /// Captures state when a discount value should be disallowed, for example,
    /// when the discount entered is higher than the total price of a product.
    ///
    @Published private(set) var discountValueIsDisallowed: Bool = false

    /// Returns true when a discount is entered, either fixed or percentage.
    ///
    var hasInputAmount: Bool {
        amount.isNotEmpty || percentage.isNotEmpty
    }

    /// Decimal value of currently entered fee or discount. For percentage type it is calculated final amount.
    ///
    private var finalAmountDecimal: Decimal {
        let decimalInput = feeOrDiscountType == .fixed
            ? priceFieldFormatter.amountDecimal
            : percentageFieldFormatter.amountDecimal

        switch feeOrDiscountType {
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
        guard let price = currencyFormatter.convertToDecimal(price) else {
            return ""
        }
        let discount = NSDecimalNumber(decimal: finalAmountDecimal)
        let priceAfterDiscount = price.subtracting(discount)
        if priceAfterDiscount.compare(NSDecimalNumber.zero) == .orderedAscending {
            updateDiscountDisallowedState(true)
            return currencyFormatter.formatAmount(priceAfterDiscount) ?? ""
        }
        updateDiscountDisallowedState(false)
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

    let lineTypeViewModel: FeeOrDiscountLineTypeViewModel

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

    enum FeeOrDiscountType: String {
        case fixed
        case percentage
    }

    @Published var feeOrDiscountType: FeeOrDiscountType = .fixed

    init(isExistingLine: Bool,
         baseAmountForPercentage: Decimal,
         initialTotal: Decimal,
         lineType: LineType,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         didSelectSave: @escaping ((Decimal?) -> Void)) {
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings, allowNegativeNumber: true)
        self.percentageFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings, allowNegativeNumber: true)
        self.percentSymbol = NumberFormatter().percentSymbol
        self.currencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.currencyPosition = storeCurrencySettings.currencyPosition
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        self.amountPlaceholder = priceFieldFormatter.formatAmount(0)
        self.analytics = analytics

        self.isExistingLine = isExistingLine
        self.baseAmountForPercentage = baseAmountForPercentage
        self.initialAmount = initialTotal

        if initialAmount != 0 {
            self.amount = priceFieldFormatter.formatAmount(initialAmount)
            self.percentage = percentageFieldFormatter.formatAmount(initialAmount / baseAmountForPercentage * 100)
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
        if let event = lineTypeViewModel.addValueEvent(with: feeOrDiscountType) {
            analytics.track(event: event)
        }

        didSelectSave(finalAmountDecimal)
    }
}

extension FeeOrDiscountLineDetailsViewModel {
    func updatePercentage(_ percentageInput: String) {
        self.percentage = percentageFieldFormatter.formatUserInput(percentageInput)
    }

    func updateAmount(_ amountInput: String) {
        self.amount = priceFieldFormatter.formatUserInput(amountInput)
    }
}

private extension FeeOrDiscountLineDetailsViewModel {
    /*
     The current implementation that we use to calculate a price after discount does not allow to update the discountValueIsDisallowed directly,
     if we attempt to do so, it would happen while the state/view is being modified, leading to undefined behaviour, and/or crashing.
     In order to avoid this we defer the state update until the current rendering cycle is complete.
     */
    func updateDiscountDisallowedState(_ value: Bool) {
        DispatchQueue.main.async {
            self.discountValueIsDisallowed = value
        }
    }
}

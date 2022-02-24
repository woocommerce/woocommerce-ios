import SwiftUI
import struct Yosemite.OrderFeeLine

class FeeLineDetailsViewModel: ObservableObject {

    /// Closure to be invoked when the fee line is updated.
    ///
    var didSelectSave: ((OrderFeeLine?) -> Void)

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
            percentage = priceFieldFormatter.formatAmount(percentage)
        }
    }

    /// Decimal value of currently entered fee. For percentage type it is calulcated final amount.
    ///
    private var finalAmountDecimal: Decimal {
        let inputString = feeType == .fixed ? amount : percentage
        guard let decimalInput = currencyFormatter.convertToDecimal(from: inputString) else {
            return .zero
        }

        switch feeType {
        case .fixed:
            return decimalInput as Decimal
        case .percentage:
            return baseAmountForPercentage * (decimalInput as Decimal) * 0.01
        }
    }

    /// The base amount (items + shipping) to apply percentage fee on.
    ///
    private let baseAmountForPercentage: Decimal

    /// The initial fee amount.
    ///
    private let initialAmount: Decimal

    /// Returns true when existing fee line is edited.
    ///
    let isExistingFeeLine: Bool

    /// Returns true when base amount for percentage > 0.
    ///
    var isPercentageOptionAvailable: Bool {
        baseAmountForPercentage > 0
    }

    /// Returns true when there are no valid pending changes.
    ///
    var shouldDisableDoneButton: Bool {
        guard finalAmountDecimal > .zero else {
            return true
        }

        return finalAmountDecimal == initialAmount
    }

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

    /// Placeholder for amount text field.
    ///
    let amountPlaceholder: String

    enum FeeType {
        case fixed
        case percentage
    }

    @Published var feeType: FeeType = .fixed

    init(inputData: NewOrderViewModel.PaymentDataViewModel,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         didSelectSave: @escaping ((OrderFeeLine?) -> Void)) {
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.percentSymbol = NumberFormatter().percentSymbol
        self.currencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.currencyPosition = storeCurrencySettings.currencyPosition
        self.currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        self.amountPlaceholder = priceFieldFormatter.formatAmount("0")

        self.isExistingFeeLine = inputData.shouldShowFees
        self.baseAmountForPercentage = inputData.feesBaseAmountForPercentage

        if let initialAmount = currencyFormatter.convertToDecimal(from: inputData.feesTotal) {
            self.initialAmount = initialAmount as Decimal
        } else {
            self.initialAmount = .zero
        }

        if initialAmount > 0, let formattedInputAmount = currencyFormatter.formatAmount(initialAmount) {
            self.amount = priceFieldFormatter.formatAmount(formattedInputAmount)
            self.percentage = priceFieldFormatter.formatAmount("\(initialAmount / baseAmountForPercentage * 100)")
        }

        self.didSelectSave = didSelectSave
    }

    func saveData() {
        guard let finalAmountString = currencyFormatter.formatAmount(finalAmountDecimal) else {
            return
        }

        let feeLine = OrderFeeLine(feeID: 0,
                                   name: "Fee",
                                   taxClass: "",
                                   taxStatus: .none,
                                   total: priceFieldFormatter.formatAmount(finalAmountString),
                                   totalTax: "",
                                   taxes: [],
                                   attributes: [])
        didSelectSave(feeLine)
    }
}

import SwiftUI
import struct Yosemite.ShippingLine

class ShippingLineDetailsViewModel: ObservableObject {

    /// Closure to be invoked when the shipping line is updated.
    ///
    var didSelectSave: ((ShippingLine?) -> Void)

    /// Helper to format price field input.
    ///
    private let priceFieldFormatter: PriceFieldFormatter

    /// Currency symbol to display with amount text field
    ///
    let currencySymbol: String

    /// Position for currency symbol, relative to amount text field
    ///
    let currencyPosition: CurrencySettings.CurrencyPosition

    /// Placeholder for amount text field
    ///
    let amountPlaceholder: String

    /// Stores the amount entered by the merchant.
    ///
    @Published var amount: String = "" {
        didSet {
            guard amount != oldValue else { return }
            amount = priceFieldFormatter.formatAmount(amount)
        }
    }

    /// Stores the method title entered by the merchant.
    ///
    @Published var methodTitle: String

    private let initialAmount: Decimal
    private let initialMethodTitle: String

    /// Returns true when existing shipping line is edited.
    ///
    let isExistingShippingLine: Bool

    /// Method title entered by user or placeholder if it's empty.
    ///
    private var finalMethodTitle: String {
        methodTitle.isNotEmpty ? methodTitle : Localization.namePlaceholder
    }

    /// Returns true when there are no valid pending changes.
    ///
    var shouldDisableDoneButton: Bool {
        guard let amountDecimal = priceFieldFormatter.amountDecimal, amountDecimal > .zero else {
            return true
        }

        let amountUpdated = amountDecimal != initialAmount
        let methodTitleUpdated = finalMethodTitle != initialMethodTitle

        return !(amountUpdated || methodTitleUpdated)
    }

    init(isExistingShippingLine: Bool,
         initialMethodTitle: String,
         shippingTotal: String,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         didSelectSave: @escaping ((ShippingLine?) -> Void)) {
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.currencySymbol = storeCurrencySettings.symbol(from: storeCurrencySettings.currencyCode)
        self.currencyPosition = storeCurrencySettings.currencyPosition
        self.amountPlaceholder = priceFieldFormatter.formatAmount("0")

        self.isExistingShippingLine = isExistingShippingLine
        self.initialMethodTitle = initialMethodTitle
        self.methodTitle = initialMethodTitle

       let currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        if let initialAmount = currencyFormatter.convertToDecimal(from: shippingTotal) {
            self.initialAmount = initialAmount as Decimal
        } else {
            self.initialAmount = .zero
        }

        if initialAmount > 0, let formattedInputAmount = currencyFormatter.formatAmount(initialAmount) {
            self.amount = priceFieldFormatter.formatAmount(formattedInputAmount)
        }

        self.didSelectSave = didSelectSave
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

// MARK: Constants

extension ShippingLineDetailsViewModel {
    enum Localization {
        static let namePlaceholder = NSLocalizedString("Shipping",
                                                       comment: "Placeholder for the name field on the Shipping Line Details screen during order creation")
    }
}

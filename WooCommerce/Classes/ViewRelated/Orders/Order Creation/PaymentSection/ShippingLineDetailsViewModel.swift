import SwiftUI
import struct Yosemite.ShippingLine

class ShippingLineDetailsViewModel: ObservableObject {

    /// Closure to be invoked when the shipping line is updated.
    ///
    var didSelectSave: ((ShippingLine?) -> Void)

    /// Helper to format price field input.
    ///
    private let priceFieldFormatter: PriceFieldFormatter

    /// Formatted amount to display. When empty displays a placeholder value.
    ///
    var formattedAmount: String {
        priceFieldFormatter.formattedAmount
    }

    /// Stores the amount(unformatted) entered by the merchant.
    ///
    @Published var amount: String = "" {
        didSet {
            guard amount != oldValue else { return }
            amount = priceFieldFormatter.formatAmount(amount)
        }
    }

    /// Defines the amount text color.
    ///
    var amountTextColor: UIColor {
        amount.isEmpty ? .textSubtle : .text
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

    init(inputData: NewOrderViewModel.PaymentDataViewModel,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         didSelectSave: @escaping ((ShippingLine?) -> Void)) {
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings)

        self.isExistingShippingLine = inputData.shouldShowShippingTotal
        self.initialMethodTitle = inputData.shippingMethodTitle
        self.methodTitle = initialMethodTitle

       let currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        if let initialAmount = currencyFormatter.convertToDecimal(from: inputData.shippingTotal) {
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

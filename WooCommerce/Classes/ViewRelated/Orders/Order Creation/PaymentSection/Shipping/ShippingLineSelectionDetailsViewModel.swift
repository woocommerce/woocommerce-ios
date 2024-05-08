import SwiftUI
import WooFoundation
import struct Yosemite.ShippingLine
import struct Yosemite.ShippingMethod
import Combine

class ShippingLineSelectionDetailsViewModel: ObservableObject {
    private var siteID: Int64

    /// Closure to be invoked when the shipping line is updated.
    ///
    var didSelectSave: ((ShippingLine?) -> Void)

    /// View model for the amount text field with currency symbol.
    ///
    let formattableAmountViewModel: FormattableAmountTextFieldViewModel

    /// Stores the method selected by the merchant.
    ///
    @Published var selectedMethod: ShippingMethod

    /// Text color for the selected method.
    ///
    var selectedMethodColor: Color {
        Color(selectedMethod.methodID == "" ? .placeholderText : .text)
    }

    /// Stores the method title entered by the merchant.
    ///
    @Published var methodTitle: String

    /// Method title entered by user or placeholder if it's empty.
    ///
    private var finalMethodTitle: String {
        methodTitle.isNotEmpty ? methodTitle : Localization.namePlaceholder
    }

    private let initialMethodID: String
    private let initialAmount: Decimal?
    private let initialMethodTitle: String

    /// Returns true when existing shipping line is edited.
    ///
    let isExistingShippingLine: Bool

    /// Available shipping methods on the store.
    ///
    let shippingMethods: [ShippingMethod]

    /// Returns true when there are valid pending changes.
    ///
    @Published var enableDoneButton: Bool = false

    init(siteID: Int64,
         shippingMethods: [ShippingMethod],
         isExistingShippingLine: Bool,
         initialMethodID: String,
         initialMethodTitle: String,
         shippingTotal: String,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         didSelectSave: @escaping ((ShippingLine?) -> Void)) {
        self.siteID = siteID
        self.isExistingShippingLine = isExistingShippingLine
        self.initialMethodID = initialMethodID
        self.initialMethodTitle = initialMethodTitle
        self.methodTitle = initialMethodTitle
        let placeholderMethod = ShippingMethod(siteID: siteID, methodID: "", title: Localization.placeholderMethodTitle)
        self.shippingMethods = [placeholderMethod] + shippingMethods
        self.selectedMethod = shippingMethods.first(where: { $0.methodID == initialMethodID }) ?? placeholderMethod

        let currencyFormatter = CurrencyFormatter(currencySettings: storeCurrencySettings)
        if isExistingShippingLine, let initialAmount = currencyFormatter.convertToDecimal(shippingTotal) {
            self.initialAmount = initialAmount as Decimal
        } else {
            self.initialAmount = nil
        }

        self.formattableAmountViewModel = FormattableAmountTextFieldViewModel(size: .title2,
                                                                              locale: locale,
                                                                              storeCurrencySettings: storeCurrencySettings,
                                                                              allowNegativeNumber: true)
        if isExistingShippingLine {
            formattableAmountViewModel.presetAmount(shippingTotal)
        }

        self.didSelectSave = didSelectSave

        observeShippingLineDetailsForUIStates(with: currencyFormatter)
    }

    /// Observes changes to the shipping line method, amount, and method title to determine the state of the "Done" button.
    ///
    func observeShippingLineDetailsForUIStates(with currencyFormatter: CurrencyFormatter) {
        formattableAmountViewModel.$amount
            .combineLatest($methodTitle, $selectedMethod)
            .map { [weak self] (amount, methodTitle, selectedMethod) in
                guard let self, let amountDecimal = currencyFormatter.convertToDecimal(amount) as? Decimal else {
                    return false
                }
                let amountUpdated = amountDecimal != self.initialAmount
                let methodTitleUpdated = methodTitle != self.initialMethodTitle
                let methodUpdated = selectedMethod.methodID != self.initialMethodID
                return amountUpdated || methodTitleUpdated || methodUpdated
        }.assign(to: &$enableDoneButton)
    }

    func saveData() {
        let shippingLine = ShippingLine(shippingID: 0,
                                        methodTitle: finalMethodTitle,
                                        methodID: selectedMethod.methodID,
                                        total: formattableAmountViewModel.amount,
                                        totalTax: "",
                                        taxes: [])
        didSelectSave(shippingLine)
    }
}

// MARK: Constants

extension ShippingLineSelectionDetailsViewModel {
    enum Localization {
        static let namePlaceholder = NSLocalizedString("order.shippingLineDetails.namePlaceholder",
                                                       value: "Shipping",
                                                       comment: "Placeholder for the name field on the Shipping Line Details screen in order form")
        static let placeholderMethodTitle = NSLocalizedString("order.shippingLineDetails.placeholderMethodTitle",
                                                              value: "N/A",
                                                              comment: "Title for the placeholder shipping method on the Shipping Line Details screen")
    }
}

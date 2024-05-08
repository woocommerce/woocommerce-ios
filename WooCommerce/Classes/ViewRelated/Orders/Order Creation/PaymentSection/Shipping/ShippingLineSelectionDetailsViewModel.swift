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

        observeFormattableAmountForUIStates(with: currencyFormatter)
    }

    func observeFormattableAmountForUIStates(with currencyFormatter: CurrencyFormatter) {
        // Maps the formatted amount to a boolean indicating whether the amount has been updated with a valid amount.
        let amountUpdated: AnyPublisher<Bool, Never> = formattableAmountViewModel.$amount.map { [weak self] amount in
            guard let self, let amountDecimal = currencyFormatter.convertToDecimal(amount) as? Decimal else {
                return false
            }
            return amountDecimal != self.initialAmount
        }.eraseToAnyPublisher()

        amountUpdated.combineLatest($methodTitle)
            .map { [weak self] (amountUpdated, methodTitle) in
                guard let self else { return false }
                let methodTitleUpdated = methodTitle != self.initialMethodTitle
                return amountUpdated || methodTitleUpdated
            }
            .assign(to: &$enableDoneButton)
    }

    func saveData() {
        // TODO-12578: Save selected shipping method ID
        let shippingLine = ShippingLine(shippingID: 0,
                                        methodTitle: finalMethodTitle,
                                        methodID: "other",
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

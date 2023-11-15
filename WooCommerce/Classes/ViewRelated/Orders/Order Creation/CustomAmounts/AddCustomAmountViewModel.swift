import Combine
import WooFoundation
import UIKit
import SwiftUI
import Yosemite

typealias CustomAmountEntered = (_ amount: String, _ name: String, _ feeID: Int64?) -> Void

final class AddCustomAmountViewModel: ObservableObject {
    let formattableAmountTextFieldViewModel: FormattableAmountTextFieldViewModel
    private var baseAmountForPercentage: Decimal
    private let onCustomAmountEntered: CustomAmountEntered
    private let analytics: Analytics
    private let currencyFormatter: CurrencyFormatter

    var baseAmountForPercentageString: String {
        currencyFormatter.formatAmount(baseAmountForPercentage) ?? ""
    }

    var showPercentageInput: Bool {
        baseAmountForPercentage > 0
    }

    init(baseAmountForPercentage: Decimal = 0,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         onCustomAmountEntered: @escaping CustomAmountEntered) {
        self.currencyFormatter = .init(currencySettings: storeCurrencySettings)
        self.formattableAmountTextFieldViewModel = FormattableAmountTextFieldViewModel(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.analytics = analytics
        self.baseAmountForPercentage = baseAmountForPercentage
        self.onCustomAmountEntered = onCustomAmountEntered
        listenToAmountChanges()

        formattableAmountTextFieldViewModel.onWillResetAmountWithNewValue = { [weak self] in
            self?.percentage = ""
        }
    }

    /// Variable that holds the name of the custom amount.
    ///
    @Published var name = ""
    @Published var percentage = "" {
        didSet {
            guard oldValue != percentage else { return }

            guard percentage.isNotEmpty else { return formattableAmountTextFieldViewModel.reset() }

            guard let decimalInput = currencyFormatter.convertToDecimal(percentage) else { return }

            formattableAmountTextFieldViewModel.presetAmount("\(baseAmountForPercentage * (decimalInput as Decimal) * 0.01)")
        }
    }

    @Published private(set) var shouldDisableDoneButton: Bool = true
    private var feeID: Int64? = nil

    var customAmountPlaceholder: String {
        Localization.customAmountPlaceholder
    }

    var doneButtonTitle: String {
        let isInEditMode = feeID != nil
        return isInEditMode ? Localization.editButtonTitle : Localization.addButtonTitle
    }

    func doneButtonPressed() {
        trackEventsOnDoneButtonPressed()

        let customAmountName = name.isNotEmpty ? name : customAmountPlaceholder
        onCustomAmountEntered(formattableAmountTextFieldViewModel.amount, customAmountName, feeID)
    }


    func preset(with fee: OrderFeeLine) {
        name = fee.name ?? Localization.customAmountPlaceholder
        formattableAmountTextFieldViewModel.presetAmount(fee.total)
        feeID = fee.feeID
    }
}

private extension AddCustomAmountViewModel {
    func listenToAmountChanges() {
        formattableAmountTextFieldViewModel.$amount.map { _ in
            !self.formattableAmountTextFieldViewModel.amountIsValid
        }.assign(to: &$shouldDisableDoneButton)
    }

    func trackEventsOnDoneButtonPressed() {
        if name.isNotEmpty {
            analytics.track(.addCustomAmountNameAdded)
        }

        if percentage.isNotEmpty {
            analytics.track(.addCustomAmountPercentageAdded)
        }

        analytics.track(.addCustomAmountDoneButtonTapped)
    }
}

private extension AddCustomAmountViewModel {
    enum Localization {
        static let addButtonTitle = NSLocalizedString("addCustomAmount.doneButton",
                                                       value: "Add Custom Amount",
                                                       comment: "Button title to confirm the custom amount on the add custom amount view in orders.")
        static let editButtonTitle = NSLocalizedString("addCustomAmount.editButton",
                                                       value: "Edit Custom Amount",
                                                       comment: "Button title to confirm the custom amount on the edit custom amount view in orders.")
        static let customAmountPlaceholder = NSLocalizedString("Custom amount",
                                                               comment: "Placeholder for the name field on the add custom amount view in orders.")
    }
}

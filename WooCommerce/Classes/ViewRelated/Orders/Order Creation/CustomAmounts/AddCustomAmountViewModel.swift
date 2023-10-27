import Combine
import WooFoundation
import UIKit
import SwiftUI
import Yosemite

typealias CustomAmountEntered = (_ amount: String, _ name: String, _ feeID: Int64?) -> Void

final class AddCustomAmountViewModel: ObservableObject {
    let formattableAmountTextFieldViewModel: FormattableAmountTextFieldViewModel
    private let onCustomAmountEntered: CustomAmountEntered
    private let analytics: Analytics

    init(locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         analytics: Analytics = ServiceLocator.analytics,
         onCustomAmountEntered: @escaping CustomAmountEntered) {
        self.formattableAmountTextFieldViewModel = FormattableAmountTextFieldViewModel(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.analytics = analytics
        self.onCustomAmountEntered = onCustomAmountEntered
        listenToAmountChanges()
    }

    /// Variable that holds the name of the custom amount.
    ///
    @Published var name = ""
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
        if name.isNotEmpty {
            analytics.track(.addCustomAmountNameAdded)
        }

        analytics.track(.addCustomAmountDoneButtonTapped)

        let customAmountName = name.isNotEmpty ? name : customAmountPlaceholder
        onCustomAmountEntered(formattableAmountTextFieldViewModel.amount, customAmountName, feeID)
    }

    func reset() {
        name = ""
        feeID = nil
        shouldDisableDoneButton = true

        formattableAmountTextFieldViewModel.reset()
    }

    func preset(with fee: OrderFeeLine) {
        name = fee.name ?? Localization.customAmountPlaceholder
        formattableAmountTextFieldViewModel.amount = fee.total
        formattableAmountTextFieldViewModel.resetAmountWithNewValue = true
        feeID = fee.feeID
    }
}

private extension AddCustomAmountViewModel {
    func listenToAmountChanges() {
        formattableAmountTextFieldViewModel.$amount.map { _ in
            !self.formattableAmountTextFieldViewModel.amountIsValid
        }.assign(to: &$shouldDisableDoneButton)
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

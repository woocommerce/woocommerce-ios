import Combine
import WooFoundation
import UIKit
import SwiftUI

typealias CustomAmountEntered = (_ amount: String, _ name: String) -> Void

final class AddCustomAmountViewModel: ObservableObject {
    let formattableAmountTextFieldViewModel: FormattableAmountTextFieldViewModel
    let onCustomAmountEntered: CustomAmountEntered

    init(locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         onCustomAmountEntered: @escaping CustomAmountEntered) {
        self.formattableAmountTextFieldViewModel = FormattableAmountTextFieldViewModel(locale: locale, storeCurrencySettings: storeCurrencySettings)
        self.onCustomAmountEntered = onCustomAmountEntered
        listenToAmountChanges()
    }

    /// Variable that holds the name of the custom amount.
    ///
    @Published var name = ""
    @Published private(set) var shouldDisableDoneButton: Bool = true

    var customAmountPlaceholder: String {
        Localization.customAmountPlaceholder
    }

    func doneButtonPressed() {
        let customAmountName = name.isNotEmpty ? name : customAmountPlaceholder
        onCustomAmountEntered(formattableAmountTextFieldViewModel.amount, customAmountName)
        reset()
    }

    func reset() {
        name = ""
        shouldDisableDoneButton = true

        formattableAmountTextFieldViewModel.reset()
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
        static let customAmountPlaceholder = NSLocalizedString("Custom amount",
                                                               comment: "Placeholder for the name field on the add custom amount view in orders.")
    }
}

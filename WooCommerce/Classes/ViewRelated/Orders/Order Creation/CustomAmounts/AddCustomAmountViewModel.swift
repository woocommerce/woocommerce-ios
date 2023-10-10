import Combine
import WooFoundation
import UIKit
import SwiftUI

final class AddCustomAmountViewModel: ObservableObject {
    let formattableAmountTextFieldViewModel: FormattableAmountTextFieldViewModel
    private var subscriptions = Set<AnyCancellable>()

    init(locale: Locale = Locale.autoupdatingCurrent, storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.formattableAmountTextFieldViewModel = FormattableAmountTextFieldViewModel(locale: locale, storeCurrencySettings: storeCurrencySettings)
        listenToAmountChanges()
    }

    /// Variable that holds the name of the custom amount.
    ///
    @Published var name = ""
    @Published var shouldDisableDoneButton: Bool = true
}

private extension AddCustomAmountViewModel {
    func listenToAmountChanges() {
        formattableAmountTextFieldViewModel.$amount.map { _ in
            !self.formattableAmountTextFieldViewModel.amountIsValid
        }.assign(to: &$shouldDisableDoneButton)
    }
}

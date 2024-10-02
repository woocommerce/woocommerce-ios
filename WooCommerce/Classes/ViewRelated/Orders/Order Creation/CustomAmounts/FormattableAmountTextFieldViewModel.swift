import Combine
import UIKit
import WooFoundation

final class FormattableAmountTextFieldViewModel: ObservableObject {
    /// Helper to format price field input.
    ///
    private let priceFieldFormatter: PriceFieldFormatter


    /// Stores the formatted amount.
    ///
    @Published private(set) var amount: String = ""

    /// Stores the value entered by the merchant and presented on the text field.
    ///
    @Published var textFieldAmountText: String = ""

    /// Stores whether the text field is focused.
    ///
    @Published var isFocused = false

    /// When true, the amount will be reset with the new input instead of appending.
    /// This is useful when we want to edit the amount with a new one from a source different than the view,
    /// otherwise we would be appending non visible decimals on the next time we edit it.
    ///
    private var resetAmountWithNewValue = false

    /// Formatted amount to display. When empty displays a placeholder value.
    ///
    var formattedAmount: String {
        priceFieldFormatter.formattedAmount
    }

    /// Defines the amount text color.
    ///
    var amountTextColor: UIColor {
        // As we don't show a cursor when editing due to implementation constraints, let's change the color also when it's focused for better visibility
        amount.isEmpty && !isFocused ? .textPlaceholder : .text
    }

    /// Defines the amount text size.
    ///
    let amountTextSize: AmountTextSize

    /// Whether the amount is allowed to be negative.
    ///
    let allowNegativeNumber: Bool

    init(size: AmountTextSize = .extraLarge,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings,
         allowNegativeNumber: Bool = false) {
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings, allowNegativeNumber: allowNegativeNumber)
        amountTextSize = size
        self.allowNegativeNumber = allowNegativeNumber

        $amount.assign(to: &$textFieldAmountText)
    }

    func reset() {
        amount = ""
    }

    func presetAmount(_ newAmount: Decimal) {
        resetAmountWithNewValue = false
        amount = priceFieldFormatter.formatAmount(newAmount)
        resetAmountWithNewValue = true
    }

    // this probably deserves a better naming :D
    // I'm not very happy that it doesn't have a single responsibility, it updates the amount and returns whether it was updated with a Bool
    // Probably it needs some refactor
    func updateAmountWithResult(_ newAmount: String) -> Bool {
        debugPrint("newAmount", newAmount)
        guard amount != newAmount else {
            debugPrint("return because it's the same as before")
            return false
        }

        let decimalAmount = Decimal(string: amount)
        debugPrint("amount", amount)
        debugPrint("decimalAmount", decimalAmount)

        // If the previous amount is 0 we have to reset it, otherwise the new input will be added to 0.00, e.g. 0.001...
        // Converting "-" to decimal returns 0, but in this case we don't want to reset the text field.
        if decimalAmount == 0 &&
            amount != "-" {
            debugPrint("reset")
            resetAmountWithNewValue = true
        }

        if resetAmountWithNewValue,
            let newInput = newAmount.last {
            amount = priceFieldFormatter.formatUserInput(String(newInput))
            debugPrint("amount with reset", amount)
            resetAmountWithNewValue = false
            return true
        }

        amount = priceFieldFormatter.formatUserInput(newAmount)
        debugPrint("amount without reset", amount)
        return true
    }

    // This function won't be necessary anymore if the function above works fine
    func updateAmount(_ newAmount: String) {
        guard amount != newAmount else {
            return
        }

        if resetAmountWithNewValue,
            let newInput = newAmount.last {
            amount = priceFieldFormatter.formatUserInput(String(newInput))
            resetAmountWithNewValue = false
        }

        amount = priceFieldFormatter.formatUserInput(newAmount)
    }
}

extension FormattableAmountTextFieldViewModel {
    enum AmountTextSize {
        case title2
        case extraLarge

        var fontSize: CGFloat {
            switch self {
            case .title2:
                return UIFont.title2.pointSize
            case .extraLarge:
                return 56
            }
        }
    }
}

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

    /// Whether the amount field should restore focus after the view is rebuilt.
    ///
    @Published var isFocused: Bool = true

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

    /// Formatted amount used as editable text. Empty input is represented by a prompt instead of editable placeholder text.
    ///
    var editableFormattedAmount: String {
        amount.isEmpty ? "" : formattedAmount
    }

    var numericTextSeparators: Set<Character> {
        priceFieldFormatter.numericTextSeparators
    }

    /// Defines the amount text color.
    ///
    var amountTextColor: UIColor {
        amount.isEmpty ? .textPlaceholder : .text
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
    }

    func reset() {
        amount = ""
    }

    func presetAmount(_ newAmount: Decimal) {
        resetAmountWithNewValue = false
        amount = priceFieldFormatter.formatAmount(newAmount)
        resetAmountWithNewValue = true
    }

    func updateAmount(_ newAmount: String) {
        updateAmount(newAmount, previousEditableAmount: nil)
    }

    func updateEditableFormattedAmount(_ newAmount: String) {
        updateAmount(newAmount, previousEditableAmount: editableFormattedAmount)
    }

    private func updateAmount(_ newAmount: String, previousEditableAmount: String?) {
        guard amount != newAmount else { return }

        if resetAmountWithNewValue,
            let newInput = newAmount.last {
            amount = priceFieldFormatter.formatUserInput(String(newInput))
            resetAmountWithNewValue = false
            return
        }

        let previousAmount = amount
        let updatedAmount = priceFieldFormatter.formatUserInput(newAmount)
        if let previousEditableAmount,
           newAmount.count < previousEditableAmount.count,
           updatedAmount == previousAmount,
           previousAmount.isNotEmpty,
           newAmount != previousEditableAmount {
            amount = priceFieldFormatter.formatUserInput(String(previousAmount.dropLast()))
        } else {
            amount = updatedAmount
        }
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

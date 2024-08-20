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

    /// When true, the amount will be reset with the new input instead of appending.
    /// This is useful when we want to edit the amount with a new one from a source different than the view,
    /// otherwise we would be appending non visible decimals on the next time we edit it.
    ///
    private var resetAmountWithNewValue = false

    var amountIsValid: Bool {
        guard let amountDecimal = priceFieldFormatter.amountDecimal else {
            return false
        }

        return allowNegativeNumber ? true : amountDecimal > .zero
    }

    /// Formatted amount to display. When empty displays a placeholder value.
    ///
    var formattedAmount: String {
        priceFieldFormatter.formattedAmount
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

        $amount.assign(to: &$textFieldAmountText)
    }

    func reset() {
        amount = ""
    }

    func presetAmount(_ newAmount: String) {
        resetAmountWithNewValue = false
        updateAmount(newAmount)
        resetAmountWithNewValue = true
    }

    func updateAmount(_ newAmount: String) {
        guard amount != newAmount else { return }

        if resetAmountWithNewValue,
            let newInput = newAmount.last {
            amount = priceFieldFormatter.formatAmount(String(newInput))
            resetAmountWithNewValue = false
            return
        }

        amount = priceFieldFormatter.formatAmount(newAmount)
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

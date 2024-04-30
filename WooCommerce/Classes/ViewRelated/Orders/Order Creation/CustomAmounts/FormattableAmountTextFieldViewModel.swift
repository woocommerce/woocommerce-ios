import Combine
import UIKit
import WooFoundation

final class FormattableAmountTextFieldViewModel: ObservableObject {
    /// Helper to format price field input.
    ///
    private let priceFieldFormatter: PriceFieldFormatter

    /// Stores the amount entered by the merchant.
    ///
    @Published var amount: String = "" {
        didSet {
            guard amount != oldValue else { return }

            if resetAmountWithNewValue,
                let newInput = amount.last {
                amount = String(newInput)
                resetAmountWithNewValue = false
            }

            amount = priceFieldFormatter.formatAmount(amount)
        }
    }

    /// When true, the amount will be reset with the new input instead of appending.
    /// This is useful when we want to edit the amount with a new one from a source different than the view,
    /// otherwise we would be appending non visible decimals on the next time we edit it.
    ///
    private var resetAmountWithNewValue = false

    var amountIsValid: Bool {
        guard let amountDecimal = priceFieldFormatter.amountDecimal else {
            return false
        }

        return amountDecimal > .zero
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
    var amountTextSize: AmountTextSize

    init(size: AmountTextSize = .extraLarge,
         locale: Locale = Locale.autoupdatingCurrent,
         storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings)
        amountTextSize = size
    }

    func reset() {
        amount = ""
    }

    func presetAmount(_ newAmount: String) {
        resetAmountWithNewValue = false
        amount = newAmount
        resetAmountWithNewValue = true
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

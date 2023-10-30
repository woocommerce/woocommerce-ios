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

    /// When true, the amount will be reset with the new input instead of appending
    /// 
    var resetAmountWithNewValue = false

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
        amount.isEmpty ? .textSubtle : .text
    }

    init(locale: Locale = Locale.autoupdatingCurrent,
        storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.priceFieldFormatter = .init(locale: locale, storeCurrencySettings: storeCurrencySettings)
    }

    func reset() {
        amount = ""
    }
}

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

            amount = priceFieldFormatter.formatAmount(amount)
        }
    }

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

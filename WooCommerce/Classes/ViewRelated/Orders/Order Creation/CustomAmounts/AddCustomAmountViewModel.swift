import Combine
import WooFoundation
import UIKit

final class AddCustomAmountViewModel: ObservableObject {
    /// Helper to format price field input.
    ///
    private let priceFieldFormatter: PriceFieldFormatter

    @Published private(set) var loading: Bool = false

    /// Stores the amount(unformatted) entered by the merchant.
    ///
    @Published var amount: String = "" {
        didSet {
            guard amount != oldValue else { return }
            amount = priceFieldFormatter.formatAmount(amount)
        }
    }

    /// Variable that holds the name of the custom amount.
    ///
    @Published var name = ""

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

    /// Returns true when the amount is not a positive number.
    ///
    var shouldDisableDoneButton: Bool {
        priceFieldFormatter.amountDecimal ==  nil
    }

    init(storeCurrencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.priceFieldFormatter = .init(locale: .autoupdatingCurrent, storeCurrencySettings: storeCurrencySettings)

    }
}

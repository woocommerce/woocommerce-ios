import Foundation
import WooFoundation

struct POSCustomAmountInput: Equatable {
    let name: String
    let amount: String
    let isTaxable: Bool
}

@Observable
final class AddCustomAmountFormViewModel {
    var amount: String = ""
    var name: String = ""
    var isTaxable: Bool = true

    let currencySymbol: String
    let sanitizer: CurrencyInputSanitizer
    private let numberFormatter: NumberFormatter

    init(currencySettings: CurrencySettings) {
        self.sanitizer = CurrencyInputSanitizer(currencySettings: currencySettings)
        self.currencySymbol = currencySettings.symbol(from: currencySettings.currencyCode)

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.generatesDecimalNumbers = true
        formatter.groupingSeparator = currencySettings.groupingSeparator
        formatter.decimalSeparator = currencySettings.decimalSeparator
        formatter.minimumFractionDigits = currencySettings.fractionDigits
        formatter.maximumFractionDigits = currencySettings.fractionDigits
        self.numberFormatter = formatter
    }

    /// Updates `amount` after running the raw user input through
    /// `CurrencyInputSanitizer`. Invalid input (extra decimals, multiple
    /// separators, etc.) is rejected and the current value is kept.
    func setAmount(_ rawInput: String) {
        guard let sanitized = sanitizer.sanitize(rawInput) else { return }
        amount = sanitized
    }

    var isAddEnabled: Bool {
        guard let value = parsedAmount else { return false }
        return value > 0
    }

    func resolvedInput() -> POSCustomAmountInput? {
        guard isAddEnabled else { return nil }
        return POSCustomAmountInput(
            name: resolvedName,
            amount: amount,
            isTaxable: isTaxable
        )
    }

    var resolvedName: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? Localization.defaultName : trimmed
    }

    private var parsedAmount: Decimal? {
        let trimmed = amount.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return numberFormatter.number(from: trimmed)?.decimalValue
    }
}

private extension AddCustomAmountFormViewModel {
    enum Localization {
        static let defaultName = NSLocalizedString(
            "pos.addCustomAmount.defaultName",
            value: "Custom amount",
            comment: "Default name used for a Point of Sale custom amount when the merchant leaves the name field empty.")
    }
}

import Foundation
import WooFoundation
import struct Yosemite.POSCustomAmount

@Observable
final class AddCustomAmountFormViewModel {
    var amount: String = ""
    var name: String = ""
    var isTaxable: Bool = true

    let currencySymbol: String
    private let sanitizer: CurrencyInputSanitizer
    private let numberFormatter: NumberFormatter
    private let editingID: UUID?
    private let resolvedID: UUID

    var isEditing: Bool { editingID != nil }

    init(currencySettings: CurrencySettings, editing existing: POSCustomAmount? = nil) {
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

        if let existing {
            self.editingID = existing.id
            self.resolvedID = existing.id
            self.amount = sanitizer.sanitize(existing.amount) ?? existing.amount
            self.name = Localization.isDefaultName(existing.name) ? "" : existing.name
            self.isTaxable = existing.isTaxable
        } else {
            self.editingID = nil
            self.resolvedID = UUID()
        }
    }

    func setAmount(_ rawInput: String) {
        guard let sanitized = sanitizer.sanitize(rawInput) else { return }
        amount = sanitized
    }

    var isAddEnabled: Bool {
        guard let value = parsedAmount else { return false }
        return value > 0
    }

    func resolvedCustomAmount() -> POSCustomAmount? {
        guard isAddEnabled else { return nil }
        return POSCustomAmount(
            id: resolvedID,
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

extension AddCustomAmountFormViewModel {
    enum Localization {
        static let defaultName = NSLocalizedString(
            "pos.addCustomAmount.defaultName",
            value: "Custom amount",
            comment: "Default name used for a Point of Sale custom amount when the merchant leaves the name field empty.")

        /// Whether `name` matches the localized default placeholder, used to clear the
        /// field when the merchant re-opens an entry they originally submitted unnamed.
        static func isDefaultName(_ name: String) -> Bool {
            name == defaultName
        }
    }
}

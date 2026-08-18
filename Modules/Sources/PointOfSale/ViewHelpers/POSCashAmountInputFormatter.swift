import Foundation
import WooFoundation

struct POSCashAmountInputFormatter {
    private let sanitizer: CurrencyInputSanitizer
    private let decimalSeparator: String

    let fractionDigits: Int

    var currencySymbol: String {
        sanitizer.currencySymbol
    }

    var hasFractionDigits: Bool {
        fractionDigits > 0
    }

    init(currencySettings: CurrencySettings) {
        self.sanitizer = CurrencyInputSanitizer(currencySettings: currencySettings)
        self.decimalSeparator = currencySettings.sanitizedDecimalSeparator
        self.fractionDigits = currencySettings.fractionDigits
    }

    func digits(from amount: Decimal) -> String {
        numericDigits(in: sanitizer.formatDecimal(amount))
    }

    func formattedAmount(from digits: String) -> String {
        let inputDigits = numericDigits(in: digits)

        guard hasFractionDigits else {
            return integerPart(from: inputDigits)
        }

        let requiredDigitCount = fractionDigits + 1
        let paddedDigits = String(repeating: "0", count: max(0, requiredDigitCount - inputDigits.count)) + inputDigits
        let fractionStartIndex = paddedDigits.index(paddedDigits.endIndex, offsetBy: -fractionDigits)
        let wholeDigits = String(paddedDigits[..<fractionStartIndex])
        let fractionalPart = String(paddedDigits[fractionStartIndex...])

        return "\(integerPart(from: wholeDigits))\(decimalSeparator)\(fractionalPart)"
    }

    /// Applies a user edit made against the formatted text to the raw digit buffer.
    /// Returns `nil` when the edit contains no digit insertion or deletion, such as tapping the decimal separator.
    func applyingEdit(
        from oldValue: String,
        to newValue: String,
        currentDigits: String,
        isReplacingPreset: Bool
    ) -> String? {
        let delta = editDelta(from: oldValue, to: newValue)
        let insertedDigits = numericDigits(in: String(delta.inserted))
        let removedDigitCount = delta.removed.filter { $0.isNumber }.count

        guard !insertedDigits.isEmpty || removedDigitCount > 0 else {
            return nil
        }

        if isReplacingPreset {
            if !insertedDigits.isEmpty {
                if removedDigitCount > 0 {
                    return numericDigits(in: newValue)
                }
                return insertedDigits
            }
            return ""
        }

        let remainingDigitCount = max(0, currentDigits.count - removedDigitCount)
        return String(currentDigits.prefix(remainingDigitCount)) + insertedDigits
    }
}

private extension POSCashAmountInputFormatter {
    func numericDigits(in value: String) -> String {
        String(value.filter { $0.isNumber })
    }

    func integerPart(from digits: String) -> String {
        let withoutLeadingZeros = digits.drop(while: { $0 == "0" })
        return withoutLeadingZeros.isEmpty ? "0" : String(withoutLeadingZeros)
    }

    func editDelta(from oldValue: String, to newValue: String) -> (removed: [Character], inserted: [Character]) {
        let oldCharacters = Array(oldValue)
        let newCharacters = Array(newValue)
        let sharedCount = min(oldCharacters.count, newCharacters.count)

        var prefixCount = 0
        while prefixCount < sharedCount,
              oldCharacters[prefixCount] == newCharacters[prefixCount] {
            prefixCount += 1
        }

        var suffixCount = 0
        while suffixCount < sharedCount - prefixCount,
              oldCharacters[oldCharacters.count - suffixCount - 1] == newCharacters[newCharacters.count - suffixCount - 1] {
            suffixCount += 1
        }

        let oldEndIndex = oldCharacters.count - suffixCount
        let newEndIndex = newCharacters.count - suffixCount
        let removed = Array(oldCharacters[prefixCount..<oldEndIndex])
        let inserted = Array(newCharacters[prefixCount..<newEndIndex])
        return (removed, inserted)
    }
}

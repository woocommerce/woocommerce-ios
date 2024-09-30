import Foundation
import WooFoundation

/// `UnitInputFormatter` implementation for decimal price input.
///
struct PriceInputFormatter: UnitInputFormatter {

    /// Currency Formatter.
    ///
    private let currencySettings: CurrencySettings

    private let numberFormatter = NumberFormatter()

    /// Number formatter with comma
    ///
    private let numberFormatterPoint: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.decimalSeparator = "."
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    /// Number formatter with comma
    ///
    private let numberFormatterComma: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.decimalSeparator = ","
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    init(currencySettings: CurrencySettings = ServiceLocator.currencySettings) {
        self.currencySettings = currencySettings
    }

    func isValid(input: String) -> Bool {
        guard input.isEmpty == false else {
            // Allows empty input to be replaced by 0.
            return true
        }

        return numberFormatterPoint.number(from: input) != nil || numberFormatterComma.number(from: input) != nil || input == numberFormatter.negativePrefix
    }

    func format(input text: String?) -> String {
        guard let text = text, text.isEmpty == false else {
            return ""
        }

        let latinText = text.applyingTransform(StringTransform.toLatin, reverse: false) ?? text

        let formattedText = latinText
            // Replace any characters not in the set of 0-9 or minus symbol with the current decimal separator configured on website
            .replacingOccurrences(of: "[^0-9-]", with: currencySettings.sanitizedDecimalSeparator, options: .regularExpression)
            // Remove any initial zero number in the string. Es. 00224.30 will be 2224.30
            .replacingOccurrences(of: "^0+([1-9]+)", with: "$1", options: .regularExpression)
            // Replace all the occurrences of regex plus all the points or comma (but not the last `.` or `,`) like thousand separators
            .replacingOccurrences(of: "(?:[.,](?=.*[.,])|)+", with: "$1", options: .regularExpression)
        return formattedText
    }
}

extension PriceInputFormatter {
    func value(from input: String) -> NSNumber? {
        guard input.isNotEmpty else {
            // Allows empty input to be replaced by 0.
            return NSNumber(value: 0)
        }

        return numberFormatterPoint.number(from: input) ?? numberFormatterComma.number(from: input)
    }
}

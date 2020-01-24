import Foundation

/// `UnitInputFormatter` implementation for decimal price input.
///
struct PriceInputFormatter: UnitInputFormatter {

    /// Currency Formatter.
    ///
    private var currencyFormatter = CurrencyFormatter()

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

    func isValid(input: String) -> Bool {
        guard input.isNotEmpty else {
            // Allows empty input to be replaced by 0.
            return true
        }

        return numberFormatterPoint.number(from: input) != nil || numberFormatterComma.number(from: input) != nil
    }

    func format(input text: String?) -> String {
        guard let text = text, text.isNotEmpty else {
            return "0"
        }

        // Replace any characters not in the set of 0-9 with the current decimal separator configured on website
        var formattedText = text.replacingOccurrences(of: "[^0-9]", with: CurrencySettings.shared.decimalSeparator, options: .regularExpression)

        // Remove any initial zero number in the string. Es. 00224.30 will be 2224.30
        formattedText = formattedText.replacingOccurrences(of: "^0+([1-9]+)", with: "$1", options: .regularExpression)
        return formattedText
    }
}

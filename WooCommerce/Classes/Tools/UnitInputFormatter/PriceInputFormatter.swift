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
        guard input.isEmpty == false else {
            // Allows empty input to be replaced by 0.
            return true
        }

        return numberFormatterPoint.number(from: input) != nil || numberFormatterComma.number(from: input) != nil
    }

    func format(input text: String?) -> String {
        guard let text = text, text.isEmpty == false else {
            return "0"
        }

        // Replace any characters not in the set of 0-9 with the current decimal separator configured on website
        let formattedText = text.replacingOccurrences(of: "[^0-9]", with: CurrencySettings.shared.decimalSeparator, options: .regularExpression)
        return formattedText
    }
}

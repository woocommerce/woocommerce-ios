import Foundation

/// `UnitInputFormatter` implementation for decimal number input.
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

        // Replace point or comma with the current decimal separator configured on website
        var formattedText = text.replacingOccurrences(of: ".", with: CurrencySettings.shared.decimalSeparator)
        formattedText = formattedText.replacingOccurrences(of: ",", with: CurrencySettings.shared.decimalSeparator)
        formattedText = formattedText.replacingOccurrences(of: "^0+([1-9]+)", with: "$1", options: .regularExpression)
        return formattedText
    }
}

import Foundation

/// `UnitInputFormatter` implementation for decimal number input.
///
struct DecimalInputFormatter: UnitInputFormatter {
    private let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        return numberFormatter
    }()

    func isValid(input: String) -> Bool {
        guard input.isEmpty == false else {
            // Allows empty input to be replaced by 0.
            return true
        }
        return numberFormatter.number(from: input) != nil
    }

    func format(input text: String?) -> String {
        guard let text = text, text.isEmpty == false else {
            return "0"
        }

        let formattedText = text.replacingOccurrences(of: "^0+([1-9]+)", with: "$1", options: .regularExpression)
        return formattedText
    }
}

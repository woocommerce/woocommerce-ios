import Foundation

/// `UnitInputFormatter` implementation for integer number input (positive, zero, negative)
///
struct IntegerInputFormatter: UnitInputFormatter {
    private let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.allowsFloats = false
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

        let formattedText = numberFormatter.number(from: text)?.stringValue ?? "0"
        return formattedText
    }
}

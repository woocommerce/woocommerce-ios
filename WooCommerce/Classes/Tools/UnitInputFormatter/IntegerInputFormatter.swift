import Foundation

/// `UnitInputFormatter` implementation for integer number input.
///
struct IntegerInputFormatter: UnitInputFormatter {
    func isValid(input: String) -> Bool {
        guard input.isNotEmpty else {
            // Allows empty input to be replaced by 0.
            return true
        }
        return Int(input) != nil
    }

    func format(input text: String?) -> String {
        guard let text = text, text.isNotEmpty else {
            return "0"
        }

        let formattedText = text
            // Removes leading 0s before the digits.
            .replacingOccurrences(of: "^0+([1-9]+)", with: "$1", options: .regularExpression)
            // Maximum one leading 0.
            .replacingOccurrences(of: "^(0+)", with: "0", options: .regularExpression)
        return formattedText
    }
}

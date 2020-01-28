import Foundation

/// `UnitInputFormatter` implementation for shipping input, like weight and dimensions (width/height/length)
///
struct ShippingInputFormatter: UnitInputFormatter {

    // Match all the characters not included in the set: numbers between 0 and 9, and - . ,
    private let regex = "[^-0-9.,]"

    func isValid(input: String) -> Bool {
        guard input.isEmpty == false else {
            // Allows empty input to be replaced by 0.
            return true
        }

        return input.range(of: regex, options: .regularExpression) == nil
    }

    func format(input text: String?) -> String {
        guard let text = text, text.isEmpty == false else {
            return ""
        }

        let formattedText = text
            // Removes leading 0s before the digits.
            .replacingOccurrences(of: "^0+([1-9]+)", with: "$1", options: .regularExpression)
            // Maximum one leading 0.
            .replacingOccurrences(of: "^(0+)", with: "0", options: .regularExpression)
            // Replace all the occurrences of regex
            .replacingOccurrences(of: regex, with: "", options: .regularExpression)
        return formattedText
    }
}

import Foundation

/// `UnitInputFormatter` implementation for integer number input (positive, negative, or zero)
///
struct IntegerInputFormatter: UnitInputFormatter {

    /// The default value used by format() when the text is empty or the number formatter return a nil value
    ///
    let defaultValue: String

    private let numberFormatter: NumberFormatter = {
        let numberFormatter = NumberFormatter()
        numberFormatter.allowsFloats = false
        return numberFormatter
    }()

    func isValid(input: String) -> Bool {
        guard input.isEmpty == false else {
            // Allows empty input to be replaced by defaultValue
            return true
        }
        return numberFormatter.number(from: input) != nil || input == "-"
    }

    func format(input text: String?) -> String {
        guard let text = text, text.isEmpty == false else {
            return defaultValue
        }

        var formattedText = numberFormatter.number(from: text)?.stringValue ?? defaultValue

        // The minus sign is mantained if present
        let minus: Character = "-"
        if text.first == minus {
            formattedText = String(minus) + formattedText.replacingOccurrences(of: "-", with: "")
        }
        return formattedText
    }

    init(defaultValue: String = "0") {
        self.defaultValue = defaultValue
    }
}

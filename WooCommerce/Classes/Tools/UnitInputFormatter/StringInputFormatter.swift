import Foundation

/// `UnitInputFormatter` implementation for string input.
///
struct StringInputFormatter: UnitInputFormatter {
    func isValid(input: String) -> Bool {
        return true
    }

    func format(input text: String?) -> String {
        return text ?? ""
    }
}

import SwiftUI

/// View model for `AddProductFromImageTextFieldView`.
final class AddProductFromImageTextFieldViewModel: ObservableObject {
    @Published var text: String
    @Published private(set) var suggestedText: String?
    let placeholder: String

    /// - Parameters:
    ///   - text: Initial value of the text.
    ///   - placeholder: Placeholder text of the text field.
    ///   - suggestedText: Initial value of the suggested text for previews and unit testing.
    init(text: String,
         placeholder: String,
         suggestedText: String? = nil) {
        self.text = text
        self.placeholder = placeholder
        self.suggestedText = suggestedText
    }

    /// Invoked when a suggestion for the text field is available.
    /// - Parameter suggestion: Suggested text for the text field.
    func onSuggestion(_ suggestion: String) {
        guard suggestion.isNotEmpty, suggestion != text else {
            return suggestedText = nil
        }
        if text.isNotEmpty {
            suggestedText = suggestion
        } else {
            text = suggestion
        }
    }

    /// Invoked when the user taps to apply the suggested text.
    func applySuggestedText() {
        text = suggestedText ?? ""
        suggestedText = nil
    }

    /// Invoked when the user taps to dismiss the suggested text.
    func dismissSuggestedText() {
        suggestedText = nil
    }
}

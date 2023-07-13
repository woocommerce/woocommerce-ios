import SwiftUI

/// Text field in the "add product from image" form.
struct AddProductFromImageTextFieldView: View {
    /// View model for `AddProductFromImageTextFieldView`.
    final class ViewModel: ObservableObject {
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

    struct Customizations {
        /// A range of number of lines for the text field.
        /// Only applicable for iOS 16.0 and up.
        let lineLimit: ClosedRange<Int>
    }

    @ObservedObject private var viewModel: ViewModel
    private let customizations: Customizations
    private let isGeneratingSuggestion: Bool

    /// - Parameters:
    ///   - viewModel: Provides text field view data.
    ///   - customizations: Customizations on the layout.
    ///   - isGeneratingSuggestion: Whether a suggestion is being generated.
    ///     This is separate from the view model since its value is shared for the main view from
    ///     `AddProductFromImageViewModel` while the view model is initialized as a separate instance.
    init(viewModel: ViewModel,
         customizations: Customizations,
         isGeneratingSuggestion: Bool) {
        self.viewModel = viewModel
        self.customizations = customizations
        self.isGeneratingSuggestion = isGeneratingSuggestion
    }

    var body: some View {
        VStack {
            // Text field.
            if #available(iOS 16.0, *) {
                TextField(viewModel.placeholder, text: $viewModel.text, axis: .vertical)
                    .lineLimit(customizations.lineLimit)
            } else {
                TextEditor(text: $viewModel.text)
            }

            HStack(spacing: Layout.defaultSpacing) {
                ProgressView()
                Text(Localization.generationInProgress)
                    .captionStyle()
                    .foregroundColor(.init(uiColor: .secondaryLabel))
                Spacer()
            }
            .renderedIf(isGeneratingSuggestion)

            // Suggested text when the suggestion becomes available while the text field is non-empty.
            if let suggestedText = viewModel.suggestedText, suggestedText.isNotEmpty, !isGeneratingSuggestion {
                VStack(alignment: .leading, spacing: Layout.defaultSpacing) {
                    Text(Localization.suggestionHeader)
                        .captionStyle()
                    Text(suggestedText)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)

                    AdaptiveStack(spacing: 0) {
                        Spacer()
                        // CTA to copy the generated text.
                        Button {
                            UIPasteboard.general.string = suggestedText
                            // TODO: 10180 - show a notice when the text is copied
                        } label: {
                            Text(Localization.copyGeneratedText)
                                .secondaryBodyStyle()
                        }
                        .buttonStyle(LinkButtonStyle())
                        .fixedSize(horizontal: true, vertical: false)

                        // CTA to replace with the generated text.
                        Button {
                            viewModel.applySuggestedText()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .fixedSize(horizontal: true, vertical: false)

                        // CTA to dismiss the generated text.
                        Button {
                            viewModel.dismissSuggestedText()
                        } label: {
                            Image(systemName: "xmark")
                        }
                        .buttonStyle(LinkButtonStyle())
                        .fixedSize(horizontal: true, vertical: false)
                    }
                }
                .padding(Layout.suggestedTextInsets)
                .background(
                    RoundedRectangle(cornerRadius: Layout.cornerRadius)
                        .foregroundColor(.init(uiColor: .tertiarySystemBackground))
                )
            }
        }
    }
}

private extension AddProductFromImageTextFieldView {
    enum Localization {
        static let generationInProgress = NSLocalizedString(
            "Generating suggestion from photo...",
            comment: "Loading state for the suggested text in the add product from image form."
        )
        static let suggestionHeader = NSLocalizedString(
            "Suggestion from photo",
            comment: "Header of the suggested text in the add product from image form."
        )
        static let copyGeneratedText = NSLocalizedString(
            "Copy",
            comment: "Button title to copy generated text in the add product from image form."
        )
    }

    enum Layout {
        static let defaultSpacing: CGFloat = 16
        static let cornerRadius: CGFloat = 8
        static let suggestedTextInsets: EdgeInsets = .init(top: 16, leading: 16, bottom: 16, trailing: 16)
    }
}

struct AddProductFromImageTextFieldView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            Section {
                AddProductFromImageTextFieldView(
                    viewModel: .init(text: "", placeholder: "Placeholder text"),
                    customizations: .init(lineLimit: 2...5),
                    isGeneratingSuggestion: true
                )
            }

            Section {
                AddProductFromImageTextFieldView(
                    viewModel: .init(text: "Xcode 15 beta enables you to develop, test, and distribute apps for all Apple platforms.",
                                     placeholder: "Placeholder text",
                                     suggestedText: "Once all the selected simulator and manifest files are downloaded"),
                    customizations: .init(lineLimit: 2...5),
                    isGeneratingSuggestion: false
                )
            }

            Section {
                AddProductFromImageTextFieldView(
                    viewModel: .init(text: "", placeholder: "Placeholder text"),
                    customizations: .init(lineLimit: 2...5),
                    isGeneratingSuggestion: false
                )
            }
            .redacted(reason: .placeholder)
            .shimmering(active: true)
        }
    }
}

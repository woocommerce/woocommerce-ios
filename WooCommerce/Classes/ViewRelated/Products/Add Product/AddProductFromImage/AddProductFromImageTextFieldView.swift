import SwiftUI

/// Text field in the "add product from image" form.
struct AddProductFromImageTextFieldView: View {
    final class ViewModel: ObservableObject {
        @Published var text: String
        let placeholder: String

        init(text: String, placeholder: String) {
            self.text = text
            self.placeholder = placeholder
        }
    }

    struct Customizations {
        /// A range of number of lines for the text field.
        /// Only applicable for iOS 16.0 and up.
        let lineLimit: ClosedRange<Int>
    }

    @ObservedObject private var viewModel: ViewModel
    private let customizations: Customizations

    init(viewModel: ViewModel, customizations: Customizations) {
        self.viewModel = viewModel
        self.customizations = customizations
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            TextField(viewModel.placeholder, text: $viewModel.text, axis: .vertical)
                .lineLimit(customizations.lineLimit)
        } else {
            TextEditor(text: $viewModel.text)
        }
    }
}

struct AddProductFromImageTextFieldView_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            Section {
                AddProductFromImageTextFieldView(
                    viewModel: .init(text: "", placeholder: "Placeholder text"),
                    customizations: .init(lineLimit: 2...5))
            }

            Section {
                AddProductFromImageTextFieldView(
                    viewModel: .init(text: "Xcode 15 beta enables you to develop, test, and distribute apps for all Apple platforms.",
                                     placeholder: "Placeholder text"),
                    customizations: .init(lineLimit: 2...5)
                )
            }

            Section {
                AddProductFromImageTextFieldView(
                    viewModel: .init(text: "", placeholder: "Placeholder text"),
                    customizations: .init(lineLimit: 2...5)
                )
            }
            .redacted(reason: .placeholder)
            .shimmering(active: true)
        }
    }
}

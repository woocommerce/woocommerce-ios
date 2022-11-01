import SwiftUI

/// Necessary data for the account creation form field.
struct AccountCreationFormFieldViewModel {
    /// Title of the field.
    let header: String
    /// Placeholder of the text field.
    let placeholder: String
    /// The type of keyboard.
    let keyboardType: UIKeyboardType
    /// Text binding for the text field.
    let text: Binding<String>
    /// Whether the content in the text field is secure, like password.
    let isSecure: Bool
    /// Optional error message shown below the text field.
    let errorMessage: String?
}

/// A field in the account creation form. Currently, there are two fields - email and password.
struct AccountCreationFormFieldView: View {
    private let viewModel: AccountCreationFormFieldViewModel

    init(viewModel: AccountCreationFormFieldViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            Text(viewModel.header)
                .subheadlineStyle()
            if viewModel.isSecure {
                SecureField(viewModel.placeholder, text: viewModel.text)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(viewModel.keyboardType)
            } else {
                TextField(viewModel.placeholder, text: viewModel.text)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(viewModel.keyboardType)
            }
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .footnoteStyle(isEnabled: true, isError: true)
            }
        }
    }
}

private extension AccountCreationFormFieldView {
    enum Layout {
        static let verticalSpacing: CGFloat = 8
    }
}

struct AccountCreationFormField_Previews: PreviewProvider {
    static var previews: some View {
        AccountCreationFormFieldView(viewModel: .init(header: "Your email address",
                                                      placeholder: "Email address",
                                                      keyboardType: .emailAddress,
                                                      text: .constant(""),
                                                      isSecure: false,
                                                      errorMessage: nil))
        AccountCreationFormFieldView(viewModel: .init(header: "Choose a password",
                                                      placeholder: "Password",
                                                      keyboardType: .default,
                                                      text: .constant("w"),
                                                      isSecure: true,
                                                      errorMessage: "Too simple"))
    }
}

import SwiftUI

/// Necessary data for the account creation form field.
struct AccountCreationFormFieldViewModel {
    /// Title of the field.
    let header: String?
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
    /// Whether the content in the text field is focused.
    let isFocused: Bool
}

/// A field in the account creation form. Currently, there are two fields - email and password.
struct AccountCreationFormFieldView: View {
    private let viewModel: AccountCreationFormFieldViewModel

    /// Whether the text field is *shown* as secure.
    /// When the field is secure, there is a button to show/hide the text field input.
    @State private var showsSecureInput: Bool = true

    // Tracks the scale of the view due to accessibility changes.
    @ScaledMetric private var scale: CGFloat = 1.0

    init(viewModel: AccountCreationFormFieldViewModel) {
        self.viewModel = viewModel
        self.showsSecureInput = viewModel.isSecure
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Layout.verticalSpacing) {
            viewModel.header.map { header in
                Text(header)
                    .foregroundColor(Color(.label))
                    .subheadlineStyle()
            }
            if viewModel.isSecure {
                ZStack(alignment: .trailing) {
                    // Text field based on the `isTextFieldSecure` state.
                    Group {
                        if showsSecureInput {
                            SecureField(viewModel.placeholder, text: viewModel.text)
                        } else {
                            TextField(viewModel.placeholder, text: viewModel.text)
                        }
                    }
                    .font(.body)
                    .textFieldStyle(RoundedBorderTextFieldStyle(
                        focused: viewModel.isFocused,
                        // Custom insets to leave trailing space for the reveal button.
                        insets: .init(top: RoundedBorderTextFieldStyle.Defaults.insets.top,
                                      leading: RoundedBorderTextFieldStyle.Defaults.insets.leading,
                                      bottom: RoundedBorderTextFieldStyle.Defaults.insets.bottom,
                                      trailing: Layout.secureFieldRevealButtonHorizontalPadding * 2 + Layout.secureFieldRevealButtonDimension * scale),
                        height: 44 * scale
                    ))
                    .keyboardType(viewModel.keyboardType)

                    // Button to show/hide the text field content.
                    Button(action: {
                        showsSecureInput.toggle()
                    }) {
                        Image(systemName: showsSecureInput ? "eye.slash" : "eye")
                            .accentColor(Color(.textSubtle))
                            .frame(width: Layout.secureFieldRevealButtonDimension * scale,
                                   height: Layout.secureFieldRevealButtonDimension * scale)
                            .padding(.leading, Layout.secureFieldRevealButtonHorizontalPadding)
                            .padding(.trailing, Layout.secureFieldRevealButtonHorizontalPadding)
                    }
                }
            } else {
                TextField(viewModel.placeholder, text: viewModel.text)
                    .textFieldStyle(RoundedBorderTextFieldStyle(focused: viewModel.isFocused))
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
        static let secureFieldRevealButtonHorizontalPadding: CGFloat = 16
        static let secureFieldRevealButtonDimension: CGFloat = 18
    }
}

struct AccountCreationFormField_Previews: PreviewProvider {
    static var previews: some View {
        AccountCreationFormFieldView(viewModel: .init(header: "Your email address",
                                                      placeholder: "Email address",
                                                      keyboardType: .emailAddress,
                                                      text: .constant(""),
                                                      isSecure: false,
                                                      errorMessage: nil,
                                                      isFocused: true))
        VStack {
            AccountCreationFormFieldView(viewModel: .init(header: "Choose a password",
                                                          placeholder: "Password",
                                                          keyboardType: .default,
                                                          text: .constant("wwwwwwwwwwwwwwwwwwwwwwww"),
                                                          isSecure: true,
                                                          errorMessage: "Too simple",
                                                          isFocused: false))
            .environment(\.sizeCategory, .medium)

            AccountCreationFormFieldView(viewModel: .init(header: "Choose a password",
                                                          placeholder: "Password",
                                                          keyboardType: .default,
                                                          text: .constant("wwwwwwwwwwwwwwwwwwwwwwww"),
                                                          isSecure: true,
                                                          errorMessage: "Too simple",
                                                          isFocused: false))
            .environment(\.sizeCategory, .extraExtraExtraLarge)
        }
    }
}

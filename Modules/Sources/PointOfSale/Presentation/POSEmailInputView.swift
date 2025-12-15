import SwiftUI

/// A view for collecting the customer's email address during POS checkout.
/// Required when the cart contains downloadable products.
struct POSEmailInputView: View {
    @Binding var email: String
    @FocusState private var isTextFieldFocused: Bool

    private var isValidEmail: Bool {
        email.contains("@") && email.contains(".")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            Text(Localization.title)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurface)

            TextField(Localization.placeholder, text: $email)
                .textFieldStyle(POSEmailTextFieldStyle())
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($isTextFieldFocused)
                .accessibilityIdentifier("pos-email-input-field")

            if !email.isEmpty && !isValidEmail {
                Text(Localization.invalidEmailHint)
                    .font(.posBodySmallRegular())
                    .foregroundColor(.posError)
            }
        }
        .padding(.horizontal, POSPadding.medium)
        .padding(.vertical, POSPadding.small)
    }
}

/// Custom text field style for email input in POS
private struct POSEmailTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(POSPadding.small)
            .background(Color.posSurfaceBright)
            .cornerRadius(POSCornerRadiusStyle.small.value)
            .overlay(
                RoundedRectangle(cornerRadius: POSCornerRadiusStyle.small.value)
                    .stroke(Color.posOutline, lineWidth: 1)
            )
            .font(.posBodyMediumRegular())
    }
}

private extension POSEmailInputView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.emailInput.title",
            value: "Customer email",
            comment: "Title for the email input field in POS checkout for downloadable products"
        )
        static let placeholder = NSLocalizedString(
            "pos.emailInput.placeholder",
            value: "Enter email for digital delivery",
            comment: "Placeholder text for the email input field in POS checkout"
        )
        static let invalidEmailHint = NSLocalizedString(
            "pos.emailInput.invalidEmail",
            value: "Please enter a valid email address",
            comment: "Error message shown when the email format is invalid"
        )
    }
}

#if DEBUG
#Preview("Empty") {
    POSEmailInputView(email: .constant(""))
}

#Preview("With Email") {
    POSEmailInputView(email: .constant("customer@example.com"))
}

#Preview("Invalid Email") {
    POSEmailInputView(email: .constant("invalid-email"))
}
#endif

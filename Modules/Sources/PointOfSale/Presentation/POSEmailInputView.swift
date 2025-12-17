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

// MARK: - Email Entry Sheet

/// A sheet for entering/editing the customer email for downloadable products
struct POSEmailEntrySheet: View {
    let email: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var emailInput: String = ""
    @FocusState private var isTextFieldFocused: Bool

    private var isValidEmail: Bool {
        emailInput.contains("@") && emailInput.contains(".")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: POSSpacing.large) {
                VStack(alignment: .leading, spacing: POSSpacing.small) {
                    Text(Localization.sheetDescription)
                        .font(.posBodyMediumRegular())
                        .foregroundColor(.posOnSurfaceVariantLowest)

                    TextField(Localization.placeholder, text: $emailInput)
                        .textFieldStyle(POSEmailTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isTextFieldFocused)
                        .accessibilityIdentifier("pos-email-sheet-input-field")

                    if !emailInput.isEmpty && !isValidEmail {
                        Text(Localization.invalidEmailHint)
                            .font(.posBodySmallRegular())
                            .foregroundColor(.posError)
                    }
                }
                .padding(.horizontal, POSPadding.medium)

                Spacer()

                Button {
                    onSave(emailInput)
                } label: {
                    Text(Localization.saveButton)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .disabled(!isValidEmail)
                .padding(.horizontal, POSPadding.medium)
                .padding(.bottom, POSPadding.medium)
            }
            .navigationTitle(Localization.sheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.cancelButton) {
                        onCancel()
                    }
                }
            }
        }
        .onAppear {
            emailInput = email
            isTextFieldFocused = true
        }
        .presentationDetents([.medium])
    }

    private enum Localization {
        static let sheetTitle = NSLocalizedString(
            "pos.emailSheet.title",
            value: "Digital delivery",
            comment: "Title for the email entry sheet in POS for downloadable products"
        )
        static let sheetDescription = NSLocalizedString(
            "pos.emailSheet.description",
            value: "Enter the customer's email address to deliver digital products after checkout.",
            comment: "Description in the email entry sheet for downloadable products"
        )
        static let placeholder = NSLocalizedString(
            "pos.emailSheet.placeholder",
            value: "customer@example.com",
            comment: "Placeholder for the email field in the email entry sheet"
        )
        static let invalidEmailHint = NSLocalizedString(
            "pos.emailSheet.invalidEmail",
            value: "Please enter a valid email address",
            comment: "Error shown when email is invalid in the email entry sheet"
        )
        static let saveButton = NSLocalizedString(
            "pos.emailSheet.save",
            value: "Save",
            comment: "Save button in the email entry sheet"
        )
        static let cancelButton = NSLocalizedString(
            "pos.emailSheet.cancel",
            value: "Cancel",
            comment: "Cancel button in the email entry sheet"
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

#Preview("Email Sheet") {
    POSEmailEntrySheet(
        email: "",
        onSave: { _ in },
        onCancel: { }
    )
}
#endif

import SwiftUI

/// A sheet for entering gift card recipient and sender details.
/// This information is required for each gift card item in the cart.
struct POSGiftCardEntrySheet: View {
    let productName: String
    let existingInfo: GiftCardInfo?
    let onSave: (GiftCardInfo) -> Void
    let onCancel: () -> Void

    @State private var recipientEmail: String = ""
    @State private var senderName: String = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case recipientEmail
        case senderName
    }

    private var isValidEmail: Bool {
        recipientEmail.contains("@") && recipientEmail.contains(".")
    }

    private var isValid: Bool {
        isValidEmail && !senderName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: POSSpacing.large) {
                VStack(alignment: .leading, spacing: POSSpacing.medium) {
                    Text(Localization.sheetDescription)
                        .font(.posBodyMediumRegular())
                        .foregroundColor(.posOnSurfaceVariantLowest)

                    // Recipient email field
                    VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                        Text(Localization.recipientEmailLabel)
                            .font(.posBodySmallRegular())
                            .foregroundColor(.posOnSurfaceVariantLowest)

                        TextField(Localization.recipientEmailPlaceholder, text: $recipientEmail)
                            .textFieldStyle(POSGiftCardTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .recipientEmail)
                            .accessibilityIdentifier("pos-gift-card-recipient-email-field")

                        if !recipientEmail.isEmpty && !isValidEmail {
                            Text(Localization.invalidEmailHint)
                                .font(.posBodySmallRegular())
                                .foregroundColor(.posError)
                        }
                    }

                    // Sender name field
                    VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                        Text(Localization.senderNameLabel)
                            .font(.posBodySmallRegular())
                            .foregroundColor(.posOnSurfaceVariantLowest)

                        TextField(Localization.senderNamePlaceholder, text: $senderName)
                            .textFieldStyle(POSGiftCardTextFieldStyle())
                            .textContentType(.name)
                            .autocorrectionDisabled()
                            .focused($focusedField, equals: .senderName)
                            .accessibilityIdentifier("pos-gift-card-sender-name-field")

                        if !senderName.trimmingCharacters(in: .whitespaces).isEmpty == false && focusedField != .senderName {
                            // Only show error after user has interacted
                        }
                    }
                }
                .padding(.horizontal, POSPadding.medium)

                Spacer()

                Button {
                    let info = GiftCardInfo(
                        recipientEmail: recipientEmail.trimmingCharacters(in: .whitespaces),
                        senderName: senderName.trimmingCharacters(in: .whitespaces)
                    )
                    onSave(info)
                } label: {
                    Text(Localization.saveButton)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal))
                .disabled(!isValid)
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
            if let existingInfo {
                recipientEmail = existingInfo.recipientEmail
                senderName = existingInfo.senderName
            }
            focusedField = .recipientEmail
        }
        .presentationDetents([.medium])
    }

    private enum Localization {
        static let sheetTitle = NSLocalizedString(
            "pos.giftCardSheet.title",
            value: "Gift card details",
            comment: "Title for the gift card entry sheet in POS"
        )
        static let sheetDescription = NSLocalizedString(
            "pos.giftCardSheet.description",
            value: "Enter the gift card recipient and sender details.",
            comment: "Description in the gift card entry sheet"
        )
        static let recipientEmailLabel = NSLocalizedString(
            "pos.giftCardSheet.recipientEmail.label",
            value: "Recipient email",
            comment: "Label for the recipient email field in gift card entry sheet"
        )
        static let recipientEmailPlaceholder = NSLocalizedString(
            "pos.giftCardSheet.recipientEmail.placeholder",
            value: "recipient@example.com",
            comment: "Placeholder for the recipient email field in gift card entry sheet"
        )
        static let senderNameLabel = NSLocalizedString(
            "pos.giftCardSheet.senderName.label",
            value: "Sender name",
            comment: "Label for the sender name field in gift card entry sheet"
        )
        static let senderNamePlaceholder = NSLocalizedString(
            "pos.giftCardSheet.senderName.placeholder",
            value: "From...",
            comment: "Placeholder for the sender name field in gift card entry sheet"
        )
        static let invalidEmailHint = NSLocalizedString(
            "pos.giftCardSheet.invalidEmail",
            value: "Please enter a valid email address",
            comment: "Error shown when email is invalid in the gift card entry sheet"
        )
        static let saveButton = NSLocalizedString(
            "pos.giftCardSheet.save",
            value: "Save",
            comment: "Save button in the gift card entry sheet"
        )
        static let cancelButton = NSLocalizedString(
            "pos.giftCardSheet.cancel",
            value: "Cancel",
            comment: "Cancel button in the gift card entry sheet"
        )
    }
}

/// Custom text field style for gift card input in POS
private struct POSGiftCardTextFieldStyle: TextFieldStyle {
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

#if DEBUG
#Preview("Empty") {
    POSGiftCardEntrySheet(
        productName: "Gift Card",
        existingInfo: nil,
        onSave: { _ in },
        onCancel: { }
    )
}

#Preview("With Existing Info") {
    POSGiftCardEntrySheet(
        productName: "Gift Card",
        existingInfo: GiftCardInfo(recipientEmail: "recipient@example.com", senderName: "John"),
        onSave: { _ in },
        onCancel: { }
    )
}
#endif

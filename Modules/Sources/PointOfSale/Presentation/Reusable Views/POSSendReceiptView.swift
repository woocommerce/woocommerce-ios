import SwiftUI
import WooFoundation
import class WordPressShared.EmailFormatValidator

struct POSSendReceiptView: View {
    @State private var textFieldInput: String = ""
    @State private var buttonState: POSButtonState = .idle
    @State private var errorMessage: String?
    @Environment(\.posAnalytics) private var analytics

    @Binding private(set) var isShowingSendReceiptView: Bool
    private let onSendReceipt: (String) async throws -> Void

    init(isShowingSendReceiptView: Binding<Bool>, onSendReceipt: @escaping (String) async throws -> Void) {
        self._isShowingSendReceiptView = isShowingSendReceiptView
        self.onSendReceipt = onSendReceipt
    }

    private var isEmailValid: Bool {
        EmailFormatValidator.validate(string: textFieldInput)
    }

    var body: some View {
        POSSingleFieldInputView(
            title: Localization.emailReceiptNavigationText,
            placeholder: Localization.textfieldPlaceholder,
            buttonTitle: Localization.buttonTitle,
            text: $textFieldInput,
            buttonState: $buttonState,
            errorMessage: $errorMessage,
            isButtonEnabled: true,
            onSubmit: { sendReceipt() },
            onClose: {
                isShowingSendReceiptView = false
            },
            keyboardType: .emailAddress,
            autocapitalization: .never,
            disableAutocorrection: true
        )
    }

    private func sendReceipt() {
        analytics.track(.pointOfSaleReceiptEmailSendTapped)
        Task { @MainActor in
            guard isEmailValid else {
                errorMessage = Localization.emailValidationErrorText
                return
            }
            buttonState = .loading
            do {
                errorMessage = nil
                try await onSendReceipt(textFieldInput)

                withAnimation {
                    buttonState = .success
                } completion: {
                    isShowingSendReceiptView = false
                }
            } catch {
                errorMessage = Localization.sendReceiptErrorText
                buttonState = .idle
            }
        }
    }
}

private extension POSSendReceiptView {
    struct Localization {
        static let buttonTitle = NSLocalizedString(
            "pointOfSale.sendreceipt.button.title",
            value: "Send",
            comment: "Button title for sending a receipt")
        static let textfieldPlaceholder = NSLocalizedString(
            "pointOfSale.sendreceipt.textfield.placeholder",
            value: "Type email",
            comment: "Placeholder for the view where an email address should be entered when sending receipts")
        static let sendReceiptErrorText = NSLocalizedString(
            "pointOfSale.sendreceipt.sendReceiptErrorText",
            value: "Error trying to send this email. Try again.",
            comment: "Generic error message that is displayed when there's an error emailing a receipt.")
        static let emailValidationErrorText = NSLocalizedString(
            "pointOfSale.sendreceipt.emailValidationErrorText",
            value: "Please enter a valid email.",
            comment: "Error message that is displayed when an invalid email is used when emailing a receipt.")
        static let emailReceiptNavigationText = NSLocalizedString(
            "pointOfSale.sendreceipt.emailReceiptNavigationText",
            value: "Email receipt",
            comment: "Text that shows at the top of the receipts screen along the back button.")
    }
}

#if DEBUG
#Preview {
    POSSendReceiptView(isShowingSendReceiptView: .constant(true)) { email in
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
    }
}
#endif

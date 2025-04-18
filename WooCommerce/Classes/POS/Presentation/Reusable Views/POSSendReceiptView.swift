import SwiftUI
import Combine
import WooFoundation
import class WordPressShared.EmailFormatValidator

@available(iOS 17.0, *)
struct POSSendReceiptView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State private var textFieldInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @FocusState private var isTextFieldFocused: Bool

    @Binding private(set) var isShowingSendReceiptView: Bool

    @State private var buttonFrame: CGRect = .zero
    @State private var keyboardFrame: CGRect = .zero
    @State private var shouldMinimizePadding: Bool = false

    private var isEmailValid: Bool {
        EmailFormatValidator.validate(string: textFieldInput)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                POSPageHeaderView(title: Localization.emailReceiptNavigationText,
                                  backButtonConfiguration: .init(state: isLoading ? .disabled: .enabled,
                                                                 action: {
                    withAnimation {
                        isShowingSendReceiptView = false
                        isTextFieldFocused = false
                    }
                }))

                VStack(alignment: .center, spacing: conditionalPadding(POSSpacing.medium)) {
                    Spacer()

                    VStack(alignment: .center, spacing: POSSpacing.xSmall) {
                        TextField("",
                                  text: $textFieldInput,
                                  prompt: Text(Localization.textfieldPlaceholder).foregroundColor(.posOnDisabledContainer))
                        .foregroundStyle(Color.posOnSurface)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .multilineTextAlignment(.center)
                        .font(POSFontStyle.posHeadingRegular)
                        .focused()
                        .focused($isTextFieldFocused)
                        .onSubmit {
                            sendReceipt()
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(POSFontStyle.posBodySmallRegular())
                                .foregroundColor(.posError)
                        }
                    }

                    Spacer()

                    Button(action: {
                        sendReceipt()
                    }, label: {
                        Text(Localization.buttonTitle)
                    })
                    .measureFrame {
                        buttonFrame = $0
                    }
                    .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isLoading))
                    .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                    .frame(maxWidth: .infinity)
                    .disabled(isLoading)
                }
                .padding([.horizontal])
                .padding(.bottom, keyboardFrame.height)
            }
            .animation(.easeInOut, value: errorMessage)
            .onChange(of: textFieldInput) { _ in
                errorMessage = nil
            }
            .onReceive(Publishers.keyboardFrame) {
                keyboardFrame = $0
                shouldMinimizePadding = $0.intersects(buttonFrame)
            }
            .animation(.default, value: shouldMinimizePadding)
        }
        .background(Color.posSurfaceBright)
    }

    private func sendReceipt() {
        ServiceLocator.analytics.track(.pointOfSaleReceiptEmailSendTapped)
        Task { @MainActor in
            guard isEmailValid else {
                errorMessage = Localization.emailValidationErrorText
                return
            }
            isLoading = true
            do {
                errorMessage = nil
                try await posModel.sendReceipt(to: textFieldInput)
                withAnimation {
                    isShowingSendReceiptView = false
                    isTextFieldFocused = false
                }
            } catch {
                errorMessage = Localization.sendReceiptErrorText
            }
            isLoading = false
        }
    }
}

@available(iOS 17.0, *)
private extension POSSendReceiptView {
    enum Constants {
        static let minimumPadding: CGFloat = POSSpacing.xSmall
    }

    private func conditionalPadding(_ padding: CGFloat) -> CGFloat {
        if shouldMinimizePadding {
            return Constants.minimumPadding
        }
        return padding
    }
}

@available(iOS 17.0, *)
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
@available(iOS 17.0, *)
#Preview {
    POSSendReceiptView(isShowingSendReceiptView: .constant(true))
        .environment(POSPreviewHelpers.makePreviewAggregateModel())
}
#endif

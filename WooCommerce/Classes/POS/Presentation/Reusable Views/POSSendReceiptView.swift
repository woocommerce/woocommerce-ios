import SwiftUI
import class WordPressShared.EmailFormatValidator

struct POSSendReceiptView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @State private var textFieldInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?
    @StateObject private var keyboardObserver = KeyboardObserver()

    @Binding private(set) var isShowingSendReceiptView: Bool

    private var isEmailValid: Bool {
        EmailFormatValidator.validate(string: textFieldInput)
    }

    private var keyboardHeight: CGFloat {
        if keyboardObserver.keyboardHeight < Constants.keyboardShownButtonSpacing {
            return Constants.keyboardShownButtonSpacing
        } else {
            return Constants.keyboardHiddenButtonSpacing
        }
    }

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Button(action: {
                    withAnimation {
                        isShowingSendReceiptView = false
                    }
                }, label: {
                    HStack {
                        Image(systemName: "chevron.backward")
                        Text(Localization.emailReceiptNavigationText)
                    }
                    .font(.posTitleEmphasized)
                    .foregroundColor(.posPrimaryText)
                    .accessibilityAddTraits(.isHeader)
                })
                Spacer()
            }
            .buttonStyle(.plain)
            .disabled(isLoading)

            TextField(Localization.textfieldPlaceholder, text: $textFieldInput)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.none)
                .autocorrectionDisabled()
                .multilineTextAlignment(.center)
                .font(POSFontStyle.posTitleRegular)
                .focused()
                .padding()
                .onSubmit {
                    sendReceipt()
                }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(POSFontStyle.posBodyRegular)
                    .foregroundColor(.red)
                    .padding(.bottom, Constants.errorMessagePadding)
            }

            Spacer().frame(height: keyboardHeight)

            Button(action: {
                sendReceipt()
            }, label: {
                HStack(spacing: Constants.buttonSpacing) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(Color.posPrimaryText)
                    } else {
                        Text(Localization.buttonTitle)
                            .font(Constants.buttonFont)
                    }
                }
                .frame(maxWidth: .infinity)
            })
            .padding(Constants.buttonPadding)
            .frame(maxWidth: .infinity)
            .foregroundColor(Color.posPrimaryTextInverted)
            .background(isEmailValid ? Color.posPrimaryButtonBackground : Color.posBackgroundButtonDisabled)
            .cornerRadius(Constants.buttonCornerRadius)
            .contentShape(Rectangle())
            .disabled(isLoading)

            Spacer()
        }
        .padding([.horizontal, .bottom])
        .animation(.easeInOut, value: errorMessage)
        .animation(.easeInOut, value: keyboardObserver.keyboardHeight)
        .onChange(of: textFieldInput) { _ in
            errorMessage = nil
        }
    }

    private func sendReceipt() {
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
                }
            } catch {
                errorMessage = Localization.sendReceiptErrorText
            }
            isLoading = false
        }
    }
}

private extension POSSendReceiptView {
    enum Constants {
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
        static let errorMessagePadding: CGFloat = 8
        static let keyboardShownButtonSpacing: CGFloat = 80
        static let keyboardHiddenButtonSpacing: CGFloat = 20
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
    let posModel = PointOfSaleAggregateModel(
        itemsController: PointOfSalePreviewItemsController(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderController: PointOfSalePreviewOrderController())
    POSSendReceiptView(isShowingSendReceiptView: .constant(true))
        .environmentObject(posModel)
}
#endif

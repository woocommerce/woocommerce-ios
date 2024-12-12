import SwiftUI
import class WordPressShared.EmailFormatValidator
import Yosemite

final class ReceiptService {
    private let orderController: PointOfSaleOrderControllerProtocol

    init(orderController: PointOfSaleOrderControllerProtocol) {
        self.orderController = orderController
    }

    func sendReceipt(to emailAddress: String) async throws {
        try await orderController.sendReceipt(recipientEmail: emailAddress)
    }
}

struct POSSendReceiptView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @State private var textFieldInput: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    @Binding private(set) var isShowingSendReceiptView: Bool

    private let receiptService: ReceiptService

    private var isEmailValid: Bool {
        EmailFormatValidator.validate(string: textFieldInput)
    }

    init(orderController: PointOfSaleOrderControllerProtocol,
         isShowingSendReceiptView: Binding<Bool>) {
            self._isShowingSendReceiptView = isShowingSendReceiptView
            self.receiptService = ReceiptService(orderController: orderController)
        }

    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            HStack {
                Button(action: {
                    isShowingSendReceiptView = false
                }, label: {
                    Image(systemName: "arrow.backward")
                        .font(.headline)
                        .foregroundColor(.primary)
                })
                Spacer()
            }
            .padding()

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
            }

            Button(action: {
                sendReceipt()
            }, label: {
                HStack(spacing: Constants.buttonSpacing) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .tint(Color.posPrimaryTextInverted)
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
            .background(Color.posOverlayFillInverted)
            .cornerRadius(Constants.buttonCornerRadius)
            .contentShape(Rectangle())
            .disabled(isLoading)

            Spacer()
        }
        .padding()
        .animation(.easeInOut, value: errorMessage)
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
                try await receiptService.sendReceipt(to: textFieldInput)
                isShowingSendReceiptView = false
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
    }
}

private extension POSSendReceiptView {
    struct Localization {
        static let buttonTitle = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.button.title",
            value: "Send",
            comment: "Button title for sending a receipt")
        static let textfieldPlaceholder = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.textfield.placeholder",
            value: "Type email",
            comment: "Placeholder for the view where an email address should be entered when sending receipts")
        static let sendReceiptErrorText = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.sendReceiptErrorText",
            value: "Error trying to send this email. Try again.",
            comment: "Generic error message that is displayed when there's an error emailing a receipt.")
        static let emailValidationErrorText = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.emailValidationErrorText",
            value: "Please enter a valid email.",
            comment: "Error message that is displayed when an invalid email is used when emailing a receipt.")
    }
}

//#if DEBUG
//#Preview {
//    let posModel = PointOfSaleAggregateModel(
//        itemsController: PointOfSalePreviewItemsController(),
//        cardPresentPaymentService: CardPresentPaymentPreviewService(),
//        orderController: PointOfSalePreviewOrderController())
//    POSSendReceiptView(orderController: posModel.orderController, isShowingSendReceiptView: .constant(true))
//        .environmentObject(posModel)
//}
//#endif

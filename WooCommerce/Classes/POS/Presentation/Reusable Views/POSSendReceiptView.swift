import SwiftUI

struct POSSendReceiptView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel

    @State private var textFieldInput: String = ""
    @State private var isLoading: Bool = false

    @Binding private(set) var isShowingSendReceiptView: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
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

            Button(action: {
                Task { @MainActor in
                    isLoading = true
                    await posModel.sendReceipt(to: textFieldInput)
                    isLoading = false
                    isShowingSendReceiptView = false
                }
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

            Spacer()
        }
        .padding()
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

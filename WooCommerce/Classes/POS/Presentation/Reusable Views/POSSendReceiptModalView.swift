import SwiftUI

struct POSSendReceiptModalView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @Environment(\.dismiss) private var dismiss

    @State private var textFieldInput: String = ""

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(alignment: .leading, spacing: 20) {
                Text(Localization.title)
                    .font(.largeTitle)
                    .bold()

                Text(Localization.subtitle)
                    .font(.headline)

                TextField(Localization.textfieldPlaceholder, text: $textFieldInput)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.none)
                    .autocorrectionDisabled()
                    .textFieldStyle(RoundedBorderTextFieldStyle(focused: true))
                    .padding(.horizontal)

                Button(action: {
                    Task { @MainActor in
                        await posModel.sendReceipt(to: textFieldInput)
                    }
                }, label: {
                    HStack(spacing: Constants.buttonSpacing) {
                        Text(Localization.buttonTitle)
                            .font(Constants.buttonFont)
                    }
                    .frame(minWidth: UIScreen.main.bounds.width / 2)
                })
                .padding(Constants.buttonPadding)
                .foregroundColor(Color.posPrimaryTextInverted)
                .background(Color.posOverlayFillInverted)
                .cornerRadius(Constants.buttonCornerRadius)

                Spacer()
            }
            .padding(.top)
            .padding()

            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
                    .font(.title2)
                    .padding()
            }
        }
    }
}

private extension POSSendReceiptModalView {
    struct Localization {
        static let title = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.title",
            value: "Receipt",
            comment: "Button title for the receipt button")
        static let subtitle = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.subtitle",
            value: "Email",
            comment: "Subtitle for the view where an email address should be entered when sending receipts")
        static let buttonTitle = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.button.title",
            value: "Send",
            comment: "Button title for sending a receipt")
        static let textfieldPlaceholder = NSLocalizedString(
            "pointOfSale.sendreceipt.modal.textfield.placeholder",
            value: "Enter an email",
            comment: "Placeholder for the view where an email address should be entered when sending receipts")
    }
    struct Constants {
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
    }
}

import SwiftUI

struct RequestReceiptView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    let sendReceipt: (String) -> ()
    @State private var textFieldInput: String = ""

    var body: some View {
        ZStack {
            Color.posPrimaryBackground.edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                Button(action: {
                    posModel.requestReceiptCompleted()
                }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text(Localization.buttonNavigationTitle)
                            .padding(.leading, Constants.buttonNavigationPadding)
                    }
                    .padding()
                    .font(.posBodyEmphasized)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Constants.buttonHeight)

                Spacer()

                HStack(spacing: Constants.buttonSpacing) {
                    TextField(Localization.textfieldPlaceholder, text: $textFieldInput)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.none)
                        .autocorrectionDisabled()
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: Constants.buttonCornerRadius)
                                .stroke(Color.black, lineWidth: 1)           )
                        .frame(height: Constants.buttonHeight)

                    Button(action: {
                        sendReceipt(textFieldInput)
                    }) {
                        HStack {
                            Image(systemName: "paperplane")
                            Text(Localization.buttonTitle)
                                .font(.body)
                        }
                        .padding()
                        .background(Color.posOverlayFillInverted)
                        .foregroundColor(Color.posPrimaryTextInverted)
                        .cornerRadius(Constants.buttonCornerRadius)
                    }
                    .frame(height: Constants.buttonHeight)
                }
                .frame(maxWidth: UIScreen.main.bounds.width * 0.5)
                .padding()

                Spacer()
            }
        }
    }
}

private extension RequestReceiptView {
    struct Localization {
        static let buttonNavigationTitle = NSLocalizedString(
            "pointOfSale.sendreceipt.button.navigation.title",
            value: "Email receipt",
            comment: "Button title for sending a receipt")
        static let buttonTitle = NSLocalizedString(
            "pointOfSale.sendreceipt.button.title",
            value: "Send",
            comment: "Button title for sending a receipt")
        static let textfieldPlaceholder = NSLocalizedString(
            "pointOfSale.sendreceipt.textfield.placeholder",
            value: "Type email",
            comment: "Placeholder for the view where an email address should be entered when sending receipts")
    }

    struct Constants {
        static let buttonSpacing: CGFloat = 12
        static let buttonPadding: CGFloat = 32
        static let buttonNavigationPadding: CGFloat = 20
        static let buttonHeight: CGFloat = 44
        static let buttonFont: POSFontStyle = .posBodyEmphasized
        static let buttonCornerRadius: CGFloat = 8
    }
}

#Preview {
    RequestReceiptView(sendReceipt: { _ in })
}

import SwiftUI
import class WordPressShared.EmailFormatValidator

struct POSSendReceiptModalView: View {
    let sendReceipt: (String) -> ()

    @State private var textFieldInput: String = ""
    @Binding var isPresented: Bool

    var isEmailValid: Bool {
        EmailFormatValidator.validate(string: textFieldInput)
    }
    @State private var isShowingInvalidEmailWarning: Bool = false

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
                    if isEmailValid {
                        isShowingInvalidEmailWarning = false
                        sendReceipt(textFieldInput)
                    } else {
                        isShowingInvalidEmailWarning = true
                    }
                }, label: {
                    HStack(spacing: Constants.buttonSpacing) {
                        Text(Localization.buttonTitle)
                            .font(Constants.buttonFont)
                            .padding(Constants.buttonPadding)
                            .foregroundColor(Color.posPrimaryTextInverted)
                            .background(isEmailValid ? .gray : Color.posOverlayFillInverted)
                    }
                })
                .buttonStyle(.plain)
                .cornerRadius(Constants.buttonCornerRadius)
                .disabled(!isEmailValid)
                
                if !isShowingInvalidEmailWarning {
                    Text("Please type a valid email address")
                        .foregroundColor(.red)
                }

                Spacer()
            }
            .padding(.top)
            .padding()
        }
        .posModalCloseButton(action: {
            isPresented = false
        })
    }
}

#Preview {
    POSSendReceiptModalView(sendReceipt: { _ in }, isPresented: .constant(true))
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

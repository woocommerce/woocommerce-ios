import SwiftUI

struct SimpleProductsModalView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack {
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Text(Localization.modalTitle)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: Constants.modalTitleWidth, height: Constants.modalTitleHeight)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.gray)
                            .frame(width: 32, height: 32)
                    }
                }
                .padding(.horizontal, 16)
                Text(Localization.modalMessage)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(width: Constants.modalMessageWidth, height: Constants.modalMessageHeight)
                    .padding(.horizontal, 16)
                VStack {
                    Text(Localization.modalHint)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(width: Constants.modalHintWidth, height: Constants.modalHintHeight)
                    Text(Localization.modalAction)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color.purple)
                        .frame(width: Constants.modalActionWidth, height: Constants.modalActionHeight)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                Button(action: {
                    isPresented = false
                }) {
                    Text("OK")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple, lineWidth: 2)
                        )
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .padding()
            .frame(width: 896, height: 486)
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.2).edgesIgnoringSafeArea(.all))
    }
}

// Constants and Localization enums
private extension SimpleProductsModalView {
    enum Constants {
        static let modalTitleWidth: CGFloat = 656
        static let modalTitleHeight: CGFloat = 40
        static let modalMessageWidth: CGFloat = 736
        static let modalMessageHeight: CGFloat = 36
        static let modalHintWidth: CGFloat = 736
        static let modalHintHeight: CGFloat = 24
        static let modalActionWidth: CGFloat = 736
        static let modalActionHeight: CGFloat = 24
    }

    enum Localization {
        static let modalTitle = NSLocalizedString(
            "pos.simpleProductsModal.title",
            value: "Why can't I see my products?",
            comment: "Title of the simple products modal"
        )
        static let modalMessage = NSLocalizedString(
            "pos.simpleProductsModal.message",
            value: "Only simple physical products can be used with POS right now.\n\n" +
                   "Other product types, such as variable and virtual, will be available in future updates.",
            comment: "Message in the simple products modal"
        )
        static let modalHint = NSLocalizedString(
            "pos.simpleProductsModal.hint",
            value: "To take payment for a non-simple product, exit POS and create a new order from the orders tab.",
            comment: "Hint in the simple products modal"
        )
        static let modalAction = NSLocalizedString(
            "pos.simpleProductsModal.action",
            value: "+ Create an order in store management",
            comment: "Action text in the simple products modal"
        )
    }
}

#if DEBUG
struct SimpleProductsModalView_Previews: PreviewProvider {
    @State static var isPresented = true
    static var previews: some View {
        SimpleProductsModalView(isPresented: $isPresented)
    }
}
#endif

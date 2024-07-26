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
                        .frame(width: 656, height: 40)
                        .multilineTextAlignment(.center)
                    Spacer()
                    Button(action: {
                        isPresented.toggle()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.gray)
                            .frame(width: 32, height: 32)
                            .padding(.top, -24) // Move the button further up
                    }
                }
                .padding(.horizontal, 16)
                
                Text(Localization.modalDescription)
                    .font(.system(size: 16))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(width: 736, height: 36)
                    .padding(.horizontal, 16)

                VStack(spacing: 8) {
                    Text(Localization.paymentDescription)
                        .font(.system(size: 14))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .frame(width: 736, height: 24)
                        .padding(.horizontal, 16)

                    Button(action: {
                        // Add action for creating an order in store management
                    }) {
                        Text(Localization.createOrder)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.purple)
                            .frame(width: 736, height: 24)
                    }
                }
                .padding(16)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                Button(action: {
                    isPresented.toggle()
                }) {
                    Text("OK")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.purple)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple, lineWidth: 2)
                        )
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
            .padding()
            .frame(width: 896, height: 486) // Fixed width and height
            .background(Color.white)
            .cornerRadius(16)
            .shadow(radius: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Center the modal
        .background(Color.black.opacity(0.2).edgesIgnoringSafeArea(.all)) // Reduced opacity
    }
}

private extension SimpleProductsModalView {
    enum Constants {
        static let modalWidth: CGFloat = 896
        static let modalHeight: CGFloat = 486
        static let titleFontSize: CGFloat = 24
        static let descriptionFontSize: CGFloat = 16
        static let paymentDescriptionFontSize: CGFloat = 14
        static let buttonFontSize: CGFloat = 18
        static let buttonCornerRadius: CGFloat = 8
        static let buttonStrokeWidth: CGFloat = 2
    }

    enum Localization {
        static let modalTitle = NSLocalizedString(
            "simpleProductsModal.title",
            value: "Why can't I see my products?",
            comment: "Title of the simple products modal"
        )
        static let modalDescription = NSLocalizedString(
            "simpleProductsModal.description",
            value: "Only simple physical products can be used with POS right now.\nOther product types, such as variable and virtual, will be available in future updates.",
            comment: "Description of the simple products modal"
        )
        static let paymentDescription = NSLocalizedString(
            "simpleProductsModal.paymentDescription",
            value: "To take payment for a non-simple product, exit POS and create a new order from the orders tab.",
            comment: "Payment description in the simple products modal"
        )
        static let createOrder = NSLocalizedString(
            "simpleProductsModal.createOrder",
            value: "+ Create an order in store management",
            comment: "Button text for creating an order in store management"
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

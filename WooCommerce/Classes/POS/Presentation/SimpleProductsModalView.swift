import SwiftUI

struct SimpleProductsModalView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .padding()
                        .foregroundColor(.gray)
                }
            }
            Text("Why can't I see my products?")
                .font(.title)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)

            Text("Only simple physical products can be used with POS right now. Other product types, such as variable and virtual, will be available in future updates.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Text("To take payment for a non-simple product, exit POS and create a new order from the orders tab.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            Button(action: {
                // Action to create an order in store management
            }) {
                Text("+ Create an order in store management")
                    .foregroundColor(.purple)
            }

            Button(action: {
                isPresented = false
            }) {
                Text("OK")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .frame(width: UIScreen.main.bounds.width * 0.75, height: UIScreen.main.bounds.height * 0.5) // Adjust the width and height to be a fraction of the screen size
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal)
    }
}

import SwiftUI

struct WooShippingPaymentMethodsView: View {

    @ObservedObject var viewModel: WooShippingPaymentMethodsViewModel

    var body: some View {
        Text("Hello, World!")
    }
}

#Preview {
    WooShippingPaymentMethodsView(viewModel: .init())
}

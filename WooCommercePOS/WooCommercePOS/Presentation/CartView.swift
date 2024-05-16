import SwiftUI

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Cart")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                .font(.title)
                .foregroundColor(Color.white)
            ForEach(viewModel.productsInCart, id: \.product.productID) { cartProduct in
                ProductRowView(cartProduct: cartProduct) {
                    viewModel.removeProductFromCart(cartProduct)
                }
                .background(Color.tertiaryBackground)
                .padding(.horizontal, 32)
            }
            Spacer()
            checkoutButton
                .padding(.horizontal, 32)

        }
        .frame(maxWidth: .infinity)
        .background(Color.secondaryBackground)
    }
}

/// View sub-components
///
private extension CartView {
    @ViewBuilder
    var checkoutButton: some View {
        Button("Checkout") {
            viewModel.submitCart()
        }
        .padding(.all, 20)
        .frame(maxWidth: .infinity, idealHeight: 120)
        .font(.title)
        .foregroundColor(Color.primaryBackground)
        .background(Color.white)
        .cornerRadius(10)
    }
}

#if DEBUG
#Preview {
    CartView(viewModel: PointOfSaleDashboardViewModel(products: ProductFactory.makeFakeProducts()))
}
#endif

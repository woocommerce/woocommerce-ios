import SwiftUI

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Cart")
                .foregroundColor(Color.white)
            ForEach(viewModel.productsInCart, id: \.product.productID) { cartProduct in
                ProductRowView(cartProduct: cartProduct) {
                    viewModel.removeProductFromCart(cartProduct)
                }
                .background(Color.tertiaryBackground)
            }
            Spacer()
            Button("Pay now") {
                viewModel.submitCart()
            }
            .background(Color.secondaryBackground)
        }
        .background(Color.secondaryBackground)
    }
}

#Preview {
    CartView(viewModel: PointOfSaleDashboardViewModel(products: ProductFactory.makeFakeProducts()))
}

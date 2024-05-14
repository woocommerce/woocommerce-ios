import SwiftUI

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ForEach(viewModel.productsInCart, id: \.product.productID) { cartProduct in
                ProductRowView(cartProduct: cartProduct) {
                    viewModel.removeProductFromCart(cartProduct)
                }
            }
            Spacer()
            Button("Pay now") {
                viewModel.submitCart()
            }
        }
    }
}

#Preview {
    CartView(viewModel: PointOfSaleDashboardViewModel(products: ProductFactory.makeFakeProducts()))
}

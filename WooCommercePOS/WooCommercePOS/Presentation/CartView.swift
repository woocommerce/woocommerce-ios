import SwiftUI

struct CartView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            ForEach(viewModel.productsInCart, id: \.product.productID) { product in
                ProductRowView(cartProduct: product)
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

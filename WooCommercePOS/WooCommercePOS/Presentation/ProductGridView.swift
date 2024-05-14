import SwiftUI

struct ProductGridView: View {
    @ObservedObject var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible()),
                                        count: viewModel.products.count)

        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(viewModel.products, id: \.productID) { product in
                    ProductCardView(product: product) {
                        viewModel.addProductToCart(product)
                    }
                }
            }
        }
        .background(Color.secondaryBackground)
    }
}

#Preview {
    ProductGridView(viewModel: PointOfSaleDashboardViewModel(products: ProductFactory.makeFakeProducts()))
}

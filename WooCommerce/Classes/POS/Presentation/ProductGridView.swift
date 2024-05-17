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
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(viewModel.products, id: \.productID) { product in
                    ProductCardView(product: product) {
                        viewModel.addProductToCart(product)
                    }
                    .foregroundColor(Color.primaryText)
                    .background(Color.secondaryBackground)
                }
            }
        }
        .background(Color.secondaryBackground)
    }
}

#Preview {
    ProductGridView(viewModel: PointOfSaleDashboardViewModel(products: POSProductFactory.makeFakeProducts(),
                                                             cardReaderConnectionViewModel: .init(state: .connectingToReader)))
}

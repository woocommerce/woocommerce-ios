import SwiftUI

struct ProductGridView: View {
    @ObservedObject var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.fixed(120)),
                                        count: viewModel.products.count)

        VStack {
            Text("Product List")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .font(.title)
                .foregroundColor(Color.white)
            HStack {
                SearchView()
                Spacer()
                FilterView(viewModel: viewModel)
            }
            .padding(.vertical, 0)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.products, id: \.productID) { product in
                        ProductCardView(product: product) {
                            viewModel.addProductToCart(product)
                        }
                        .foregroundColor(Color.primaryText)
                        .background(Color.secondaryBackground)
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .background(Color.secondaryBackground)
    }
}

#if DEBUG
#Preview {
    ProductGridView(viewModel: PointOfSaleDashboardViewModel(products: POSProductFactory.makeFakeProducts(),
                                                             cardReaderConnectionViewModel: .init(state: .connectingToReader)))
}
#endif

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
            Text("Product List")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 32)
                .padding(.vertical, 8)
                .font(.title)
                .foregroundColor(Color.white)
            HStack {
                SearchView()
                    .padding(.top, 20)
                    .padding(.horizontal, 32)
                Spacer()
                FilterView()
                    .padding(.top, 20)
                    .padding(.horizontal, 32)
            }
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

struct SearchView: View {
    var body: some View {
        TextField("Search", text: .constant("Search"))
            .frame(maxWidth: .infinity, idealHeight: 120)
            .font(.title2)
            .foregroundColor(Color.white)
            .background(Color.secondaryBackground)
            .cornerRadius(10)
            .border(Color.white, width: 2)
    }
}

struct FilterView: View {
    var body: some View {
        Button("Filter") {
            // TODO:
        }
        .frame(maxWidth: .infinity, idealHeight: 120)
        .font(.title2)
        .foregroundColor(Color.white)
        .background(Color.secondaryBackground)
        .cornerRadius(10)
        .border(Color.white, width: 2)
    }
}

#Preview {
    ProductGridView(viewModel: PointOfSaleDashboardViewModel(products: POSProductFactory.makeFakeProducts(),
                                                             cardReaderConnectionViewModel: .init(state: .connectingToReader)))
}

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
                    Button(action: {
                        viewModel.callbackFromProductSelector(product)
                    }, label: {
                        VStack {
                            Text(product.name)
                            // TODO: CurrencyFormatter
                            Text(product.price)
                        }
                        .padding()
                        .background(Color.cyan)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
                    })
                }
            }
        }
    }
}

#Preview {
    ProductGridView(viewModel: PointOfSaleDashboardViewModel(products: ProductFactory.makeFakeProducts()))
}

import SwiftUI

struct ItemGridView: View {
    @ObservedObject var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.fixed(Constants.itemWidth)),
                                        count: Constants.maxItemsPerRow)

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
                    ForEach(viewModel.items, id: \.productID) { item in
                        ItemCardView(item: item) {
                            viewModel.addItemToCart(item)
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

private extension ItemGridView {
    enum Constants {
        static let maxItemsPerRow: Int = 2
        static let itemWidth: CGFloat = 325.0
    }
}

#if DEBUG
#Preview {
    ItemGridView(viewModel: PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                          cardPresentPaymentService: CardPresentPaymentService(siteID: 0)))
}
#endif

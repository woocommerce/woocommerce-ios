import class Yosemite.POSProductProvider
import SwiftUI

struct ItemGridView: View {
    @ObservedObject var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.fixed(120)),
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
        static let maxItemsPerRow: Int = 4
    }
}

#if DEBUG
#Preview {
    // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12917
    // The Yosemite imports are only needed for previews
    ItemGridView(viewModel: PointOfSaleDashboardViewModel(items: POSProductProvider.provideProductsForPreview(),
                                                          cardPresentPaymentService: CardPresentPaymentPreviewService()))
}
#endif

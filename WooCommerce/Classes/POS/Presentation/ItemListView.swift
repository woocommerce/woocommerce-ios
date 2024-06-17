import SwiftUI

struct ItemListView: View {
    @ObservedObject var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("Products")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .font(.title)
                .foregroundColor(Color.white)
            ScrollView {
                ForEach(viewModel.items, id: \.productID) { item in
                    ItemCardView(item: item) {
                        viewModel.addItemToCart(item)
                    }
                    .foregroundColor(Color.primaryText)
                    .background(Color.secondaryBackground)
                }
            }
        }
        .padding(.horizontal, 32)
        .background(Color.secondaryBackground)
    }
}

#if DEBUG
#Preview {
    ItemListView(viewModel: PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                          cardPresentPaymentService: CardPresentPaymentPreviewService()))
}
#endif

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
                .foregroundColor(Color.posPrimaryTexti3)
            ScrollView {
                ForEach(viewModel.items, id: \.productID) { item in
                    Button(action: {
                        viewModel.addItemToCart(item)
                    }, label: {
                        ItemCardView(item: item)
                    })
                }
            }
        }
        .padding(.horizontal, 32)
        .background(Color.posBackgroundGreyi3)
    }
}

#if DEBUG
#Preview {
    ItemListView(viewModel: PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                          cardPresentPaymentService: CardPresentPaymentPreviewService()))
}
#endif

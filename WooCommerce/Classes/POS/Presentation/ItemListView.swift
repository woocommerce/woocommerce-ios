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
            if viewModel.isSyncingItems {
                Spacer()
                Text("Loading...")
                Spacer()
            } else {
                ScrollView {
                    ForEach(viewModel.items, id: \.productID) { item in
                        Button(action: {
                            viewModel.cartViewModel.addItemToCart(item)
                        }, label: {
                            ItemCardView(item: item)
                        })
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .background(Color.posBackgroundGreyi3)
    }
}

#if DEBUG
import class Yosemite.POSOrderService
import enum Yosemite.Credentials
#Preview {
    ItemListView(viewModel: PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                                          cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                          orderService: POSOrderPreviewService()))
}
#endif

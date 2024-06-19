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
                    Button(action: {
                        viewModel.addItemToCart(item)
                    }, label: {
                        ItemCardView(item: item)
                    })
                }
            }
        }
        .padding(.horizontal, 32)
        .background(Color.secondaryBackground)
    }
}

#if DEBUG
import class Yosemite.POSOrderService
import enum Yosemite.Credentials
#Preview {
    ItemListView(viewModel: PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                          cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                          orderService: POSOrderService(siteID: Int64.min,
                                                                                        credentials: Credentials(authToken: "token"))))
}
#endif

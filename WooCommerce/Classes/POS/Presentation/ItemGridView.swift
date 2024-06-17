import SwiftUI
import protocol Yosemite.PointOfSaleOrderServiceProtocol
import class Yosemite.PointOfSaleOrderService
import enum Networking.Credentials

struct ItemGridView: View {
    @ObservedObject var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        let columns: [GridItem] = Array(repeating: .init(.flexible(minimum: Constants.minItemWidth,
                                                                   maximum: Constants.maxItemWidth)),
                                        count: Constants.maxItemsPerRow)

        VStack {
            Text("Products")
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .font(.title)
                .foregroundColor(Color.white)
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
        static let minItemWidth: CGFloat = 250.0
        static let maxItemWidth: CGFloat = 325.0
    }
}

#if DEBUG
#Preview {
    ItemGridView(viewModel: PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                          cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                          orderService: PointOfSaleOrderService(siteID: Int64.min, credentials: Credentials(authToken: "token"))))
}
#endif

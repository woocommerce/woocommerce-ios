import SwiftUI
import protocol Yosemite.PointOfSaleOrderServiceProtocol
import class Yosemite.PointOfSaleOrderService
import enum Networking.Credentials

struct FilterView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button("Filter") {
            // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12761
            viewModel.showFilters()
        }
        .frame(maxWidth: .infinity, idealHeight: 120)
        .font(.title2)
        .foregroundColor(Color.white)
        .background(Color.secondaryBackground)
        .cornerRadius(10)
        .border(Color.white, width: 2)
    }
}

#if DEBUG
#Preview {
    FilterView(viewModel: PointOfSaleDashboardViewModel(items: [],
                                                        cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                        orderService: PointOfSaleOrderService(siteID: Int64.min,
                                                                                              credentials: Credentials(authToken: "token"))))
}
#endif

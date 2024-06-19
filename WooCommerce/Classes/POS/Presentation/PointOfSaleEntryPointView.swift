import SwiftUI
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSOrderServiceProtocol

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel

    private let hideAppTabBar: ((Bool) -> Void)

    init(itemProvider: POSItemProvider,
         hideAppTabBar: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol) {
        self.hideAppTabBar = hideAppTabBar

        _viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            items: itemProvider.providePointOfSaleItems(),
            cardPresentPaymentService: cardPresentPaymentService,
            orderService: orderService)
        )
    }

    var body: some View {
        PointOfSaleDashboardView(viewModel: viewModel)
            .onAppear {
                hideAppTabBar(true)
            }
            .onDisappear {
                hideAppTabBar(false)
            }
    }
}

#if DEBUG
import enum Yosemite.Credentials
import class Yosemite.POSOrderService
#Preview {
    PointOfSaleEntryPointView(itemProvider: POSItemProviderPreview(),
                              hideAppTabBar: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderService: POSOrderService(siteID: Int64.min, credentials: Credentials(authToken: "token")))
}
#endif

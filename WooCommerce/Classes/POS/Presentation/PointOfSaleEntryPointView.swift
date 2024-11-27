import SwiftUI

struct PointOfSaleEntryPointView: View {
    @StateObject private var posModel: PointOfSaleAggregateModel
    @StateObject private var posModalManager = POSModalManager()

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)

    init(itemsController: PointOfSaleItemsControllerProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        let posModel = PointOfSaleAggregateModel(
            itemsController: itemsController,
            cardPresentPaymentService: cardPresentPaymentService,
            orderController: orderController)

        self._posModel = StateObject(wrappedValue: posModel)
    }

    var body: some View {
        PointOfSaleDashboardView()
        .environmentObject(posModalManager)
        .environmentObject(posModel)
        .onAppear {
            onPointOfSaleModeActiveStateChange(true)
        }
        .onDisappear {
            onPointOfSaleModeActiveStateChange(false)
        }
    }
}

#if DEBUG
#Preview {
    PointOfSaleEntryPointView(itemsController: PointOfSalePreviewItemsController(),
                              onPointOfSaleModeActiveStateChange: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderController: PointOfSalePreviewOrderController())
}
#endif

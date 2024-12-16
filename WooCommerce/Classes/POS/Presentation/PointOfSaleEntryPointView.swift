import SwiftUI

struct PointOfSaleEntryPointView: View {
    @StateObject private var posModel: PointOfSaleAggregateModel
    @StateObject private var posModalManager = POSModalManager()

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)
    private let onExit: () -> Void

    init(itemsController: PointOfSaleItemsControllerProtocol,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         onExit: @escaping () -> Void,
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderController: PointOfSaleOrderControllerProtocol) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange
        self.onExit = onExit

        let posModel = PointOfSaleAggregateModel(
            itemsController: itemsController,
            cardPresentPaymentService: cardPresentPaymentService,
            orderController: orderController)

        self._posModel = StateObject(wrappedValue: posModel)
    }

    var body: some View {
        PointOfSaleDashboardView(onExit: onExit)
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
                              onExit: {},
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderController: PointOfSalePreviewOrderController())
}
#endif

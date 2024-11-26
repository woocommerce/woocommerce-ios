import SwiftUI
import protocol Yosemite.POSItemProvider
import protocol Yosemite.POSOrderServiceProtocol

struct PointOfSaleEntryPointView: View {
    @StateObject private var posModel: PointOfSaleAggregateModel
    @StateObject private var posModalManager = POSModalManager()

    private let onPointOfSaleModeActiveStateChange: ((Bool) -> Void)

    init(itemProvider: POSItemProvider,
         onPointOfSaleModeActiveStateChange: @escaping ((Bool) -> Void),
         cardPresentPaymentService: CardPresentPaymentFacade,
         orderService: POSOrderServiceProtocol) {
        self.onPointOfSaleModeActiveStateChange = onPointOfSaleModeActiveStateChange

        let posModel = PointOfSaleAggregateModel(itemsService: PointOfSaleItemsService(itemProvider: itemProvider),
                                                 cardPresentPaymentService: cardPresentPaymentService,
                                                 orderService: orderService)

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
    PointOfSaleEntryPointView(itemProvider: POSItemProviderPreview(),
                              onPointOfSaleModeActiveStateChange: { _ in },
                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                              orderService: POSOrderPreviewService())
}
#endif

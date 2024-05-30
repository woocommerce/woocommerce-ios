import SwiftUI
import class WooFoundation.CurrencySettings
import protocol Yosemite.POSItemProvider

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel
    private var itemProvider: POSItemProvider

    private let hideAppTabBar: ((Bool) -> Void)

    init(itemProvider: POSItemProvider, currencySettings: CurrencySettings, hideAppTabBar: @escaping ((Bool) -> Void)) {
        self.itemProvider = itemProvider
        self.hideAppTabBar = hideAppTabBar

        _viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            products: itemProvider.providePointOfSaleItems(),
            cardReaderConnectionViewModel: .init(state: .connectingToReader),
            currencySettings: .init())
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
//#Preview {
//    PointOfSaleEntryPointView(currencySettings: ServiceLocator.currencySettings, hideAppTabBar: { _ in })
//}
#endif

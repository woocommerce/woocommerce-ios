import SwiftUI
import class WooFoundation.CurrencySettings

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel

    private let hideAppTabBar: ((Bool) -> Void)

    init(currencySettings: CurrencySettings, hideAppTabBar: @escaping ((Bool) -> Void)) {
        self.hideAppTabBar = hideAppTabBar

        _viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            products: POSProductFactory().makePointOfSaleProducts(),
            cardReaderConnectionViewModel: .init(state: .connectingToReader))
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
#Preview {
    PointOfSaleEntryPointView(currencySettings: ServiceLocator.currencySettings, hideAppTabBar: { _ in })
}
#endif

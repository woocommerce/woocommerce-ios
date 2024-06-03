import SwiftUI
import class WooFoundation.CurrencySettings

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel

    private let hideAppTabBar: ((Bool) -> Void)

    init(currencySettings: CurrencySettings, hideAppTabBar: @escaping ((Bool) -> Void), siteID: Int64) {
        self.hideAppTabBar = hideAppTabBar

        _viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            products: POSProductProvider().providePointOfSaleProducts(),
            currencySettings: .init(),
            cardPresentPaymentService: CardPresentPaymentService(siteID: siteID))
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
    PointOfSaleEntryPointView(currencySettings: ServiceLocator.currencySettings, hideAppTabBar: { _ in }, siteID: 0)
}
#endif

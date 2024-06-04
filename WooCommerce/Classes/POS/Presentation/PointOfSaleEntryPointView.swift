import SwiftUI
import protocol Yosemite.POSItemProvider
import class Yosemite.NullPOSProductProvider
import class WooFoundation.CurrencySettings

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel

    private let hideAppTabBar: ((Bool) -> Void)

    init(itemProvider: POSItemProvider, currencySettings: CurrencySettings, hideAppTabBar: @escaping ((Bool) -> Void), siteID: Int64) {
        self.hideAppTabBar = hideAppTabBar

        _viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            items: itemProvider.providePointOfSaleItems(),
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
    // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12917
    // Some Yosemite imports are only needed for previews
    PointOfSaleEntryPointView(itemProvider: NullPOSProductProvider(), currencySettings: ServiceLocator.currencySettings, hideAppTabBar: { _ in }, siteID: 0)
}
#endif

import SwiftUI
import class WooFoundation.CurrencySettings

struct PointOfSaleEntryPointView: View {
    // TODO:
    // Temporary. DI proper product models once we have a data layer
    private let viewModel: PointOfSaleDashboardViewModel

    private let hideAppTabBar: ((Bool) -> Void)
    private let currencySettings: CurrencySettings

    // Necessary to expose the View's entry point to WooCommerce
    // Otherwise the current switch on `HubMenu` where this View is created
    // will error with "No exact matches in reference to static method 'buildExpression'"
    public init(currencySettings: CurrencySettings, hideAppTabBar: @escaping ((Bool) -> Void)) {
        self.currencySettings = currencySettings
        self.hideAppTabBar = hideAppTabBar
        let products = POSProductFactory.makeFakeProducts(currencySettings: currencySettings)
        let viewModel = PointOfSaleDashboardViewModel(products: products, cardReaderConnectionViewModel: .init(state: .scanningForReader(cancel: {})))
        self.viewModel = viewModel
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

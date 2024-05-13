import SwiftUI

public struct PointOfSaleEntryPointView: View {
    // TODO:
    // Temporary. DI proper product models once we have a data layer
    private let viewModel: PointOfSaleDashboardViewModel = {
        let products = ProductFactory.makeFakeProducts()
        let viewModel = PointOfSaleDashboardViewModel(products: products)

        return viewModel
    }()

    private let hideAppTabBar: ((Bool) -> Void)

    // Necessary to expose the View's entry point to WooCommerce
    // Otherwise the current switch on `HubMenu` where this View is created
    // will error with "No exact matches in reference to static method 'buildExpression'"
    public init(hideAppTabBarsCallback: @escaping ((Bool) -> Void)) {
        self.hideAppTabBar = hideAppTabBarsCallback
    }

    public var body: some View {
        PointOfSaleDashboardView(viewModel: viewModel)
            .onAppear {
                hideAppTabBar(true)
            }
            .onDisappear {
                hideAppTabBar(false)
            }
    }
}

#Preview {
    PointOfSaleEntryPointView(hideAppTabBarsCallback: { _ in })
}

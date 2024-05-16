import SwiftUI

public struct PointOfSaleEntryPointView: View {
    // TODO:
    // Temporary. DI proper product models once we have a data layer
    private let viewModel: PointOfSaleDashboardViewModel

    private let hideAppTabBar: ((Bool) -> Void)

    // Necessary to expose the View's entry point to WooCommerce
    // Otherwise the current switch on `HubMenu` where this View is created
    // will error with "No exact matches in reference to static method 'buildExpression'"
    init(dependencies: PointOfSaleDependencies, hideAppTabBar: @escaping ((Bool) -> Void)) {
        self.hideAppTabBar = hideAppTabBar
        self.viewModel = {
            let products = POSProductFactory.makeFakeProducts()
            let viewModel = PointOfSaleDashboardViewModel(products: products,
                                                          cardReaderConnectionViewModel: .init(state: .scanningForReader(cancel: {})),
                                                          dependencies: dependencies)
            return viewModel
        }()
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
    PointOfSaleEntryPointView(dependencies: .init(siteID: 1,
                                                  cardPresentPaymentsConfiguration: .init(country: .US)),
                              hideAppTabBar: { _ in })
}

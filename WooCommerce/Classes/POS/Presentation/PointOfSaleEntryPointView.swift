import SwiftUI

struct PointOfSaleEntryPointView: View {
    // TODO:
    // Temporary. DI proper product models once we have a data layer
    private let viewModel: PointOfSaleDashboardViewModel = {
        let products = POSProductFactory.makeFakeProducts()
        let viewModel = PointOfSaleDashboardViewModel(products: products, cardReaderConnectionViewModel: .init(state: .scanningForReader(cancel: {})))

        return viewModel
    }()

    private let hideAppTabBar: ((Bool) -> Void)

    private let testPaymentViewModel: PointOfSalePaymentsTestViewModel

    // Necessary to expose the View's entry point to WooCommerce
    // Otherwise the current switch on `HubMenu` where this View is created
    // will error with "No exact matches in reference to static method 'buildExpression'"
    init(hideAppTabBar: @escaping ((Bool) -> Void),
         testPaymentViewModel: PointOfSalePaymentsTestViewModel) {
        self.hideAppTabBar = hideAppTabBar
        self.testPaymentViewModel = testPaymentViewModel
    }

    var body: some View {
        PointOfSaleDashboardView(viewModel: viewModel,
                                 testPaymentViewModel: testPaymentViewModel)
            .onAppear {
                hideAppTabBar(true)
            }
            .onDisappear {
                hideAppTabBar(false)
            }
    }
}

#Preview {
    PointOfSaleEntryPointView(hideAppTabBar: { _ in }, testPaymentViewModel: PointOfSalePaymentsTestViewModel(siteID: 123))
}

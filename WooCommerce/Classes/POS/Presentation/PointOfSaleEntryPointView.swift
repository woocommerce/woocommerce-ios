import SwiftUI

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel = PointOfSaleDashboardViewModel(
        products: POSProductFactory.makeFakeProducts(),
        cardReaderConnectionViewModel: .init(state: .connectingToReader)
    )

    private let hideAppTabBar: ((Bool) -> Void)

    // Necessary to expose the View's entry point to WooCommerce
    // Otherwise the current switch on `HubMenu` where this View is created
    // will error with "No exact matches in reference to static method 'buildExpression'"
    public init(hideAppTabBar: @escaping ((Bool) -> Void)) {
        self.hideAppTabBar = hideAppTabBar
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
    PointOfSaleEntryPointView(hideAppTabBar: { _ in })
}
#endif

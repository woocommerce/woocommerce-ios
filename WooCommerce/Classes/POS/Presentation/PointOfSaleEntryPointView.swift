import SwiftUI

public struct PointOfSaleEntryPointView: View {
    // TODO:
    // Temporary. DI proper product models once we have a data layer
    private let viewModel: PointOfSaleDashboardViewModel = {
        let products = POSProductFactory.makeFakeProducts()
        let viewModel = PointOfSaleDashboardViewModel(products: products, cardReaderConnectionViewModel: .init(state: .scanningForReader(cancel: {})))

        return viewModel
    }()

    private let historyViewModel: PointOfSaleHistoryViewModel = PointOfSaleHistoryViewModel(items: [
        HistoryItem(createdAt: Date(), amountInCents: 299),
        HistoryItem(createdAt: Date() - 1000, amountInCents: 399)
    ])

    private let hideAppTabBar: ((Bool) -> Void)

    // Necessary to expose the View's entry point to WooCommerce
    // Otherwise the current switch on `HubMenu` where this View is created
    // will error with "No exact matches in reference to static method 'buildExpression'"
    public init(hideAppTabBar: @escaping ((Bool) -> Void)) {
        self.hideAppTabBar = hideAppTabBar
    }

    public var body: some View {
        PointOfSaleDashboardView(viewModel: viewModel, historyViewModel: historyViewModel)
            .onAppear {
                hideAppTabBar(true)
                historyViewModel.startSession()
            }
            .onDisappear {
                hideAppTabBar(false)
                historyViewModel.endSession()
            }
    }
}

#Preview {
    PointOfSaleEntryPointView(hideAppTabBar: { _ in })
}

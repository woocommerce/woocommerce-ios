import SwiftUI

struct PointOfSaleEntryPointView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    private let hideAppTabBar: ((Bool) -> Void)

    // Necessary to expose the View's entry point to WooCommerce
    // Otherwise the current switch on `HubMenu` where this View is created
    // will error with "No exact matches in reference to static method 'buildExpression'"
    public init(viewModel: PointOfSaleDashboardViewModel, hideAppTabBar: @escaping ((Bool) -> Void)) {
        self.viewModel = viewModel
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
    PointOfSaleEntryPointView(viewModel: .defaultPreview(), hideAppTabBar: { _ in })
}
#endif

import SwiftUI

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel = PointOfSaleDashboardViewModel(
        products: POSProductFactory.makeFakeProducts(),
        cardReaderConnectionViewModel: .init(state: .connectingToReader)
    )

    private let hideAppTabBar: ((Bool) -> Void)

    init(hideAppTabBar: @escaping ((Bool) -> Void)) {
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

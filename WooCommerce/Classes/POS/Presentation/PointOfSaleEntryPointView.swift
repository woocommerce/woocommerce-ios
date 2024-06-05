import SwiftUI
import protocol Yosemite.POSItemProvider
import class Yosemite.NullPOSProductProvider

struct PointOfSaleEntryPointView: View {
    @StateObject private var viewModel: PointOfSaleDashboardViewModel

    private let hideAppTabBar: ((Bool) -> Void)

    init(itemProvider: POSItemProvider, hideAppTabBar: @escaping ((Bool) -> Void), siteID: Int64) {
        self.hideAppTabBar = hideAppTabBar

        _viewModel = StateObject(wrappedValue: PointOfSaleDashboardViewModel(
            items: itemProvider.providePointOfSaleItems(),
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
    PointOfSaleEntryPointView(itemProvider: NullPOSProductProvider(), hideAppTabBar: { _ in }, siteID: 0)
}
#endif

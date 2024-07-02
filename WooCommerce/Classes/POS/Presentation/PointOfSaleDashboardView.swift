import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            HStack {
                switch viewModel.orderStage {
                case .building:
                    productListView
                    Spacer()
                    if viewModel.isCartCollapsed {
                        collapsedCartView
                    } else {
                        cartView
                    }
                case .finalizing:
                    if !viewModel.areTotalsFullScreen {
                        cartView
                        Spacer()
                    }
                    totalsView
                }
            }
            .padding()
        }
        .background(Color.posBackgroundGreyi3)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                POSToolbarView(readerConnectionViewModel: viewModel.cardReaderConnectionViewModel,
                               isExitPOSDisabled: $viewModel.isExitPOSDisabled)
            }
        }
        .toolbarBackground(Color.toolbarBackground, for: .bottomBar)
        .toolbarBackground(.visible, for: .bottomBar)
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var collapsedCartView: some View {
        CollapsedCartView()
    }

    var cartView: some View {
        CartView(viewModel: viewModel,
                 cartViewModel: viewModel.cartViewModel)
        .frame(maxWidth: .infinity)
    }

    var totalsView: some View {
        TotalsView(viewModel: viewModel,
                   totalsViewModel: viewModel.totalsViewModel)
        .background(Color(UIColor.systemBackground))
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
    }

    var productListView: some View {
        ItemListView(viewModel: viewModel.itemSelectorViewModel)
            .frame(maxWidth: .infinity)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PointOfSaleDashboardView(
            viewModel: PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                                     cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                     orderService: POSOrderPreviewService(),
                                                     currencyFormatter: .init(currencySettings: .init())))
    }
}
#endif

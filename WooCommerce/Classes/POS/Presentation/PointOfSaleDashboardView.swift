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
                    productGridView
                    Spacer()
                    if viewModel.isCartCollapsed {
                        collapsedCartView
                    } else {
                        cartView
                    }
                case .finalizing:
                    cartView
                    Spacer()
                    totalsView
                }
            }
            .padding()
        }
        .task {
            // Q-JC: can this task be moved to `ItemListView`?
            await viewModel.itemSelectorViewModel.populatePointOfSaleItems()
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
        CartView(dashboardViewModel: viewModel,
                 cartViewModel: viewModel.cartViewModel)
        .frame(maxWidth: .infinity)
    }

    var totalsView: some View {
        TotalsView(dashboardViewModel: viewModel,
                   totalsViewModel: viewModel.totalsViewModel)
        .background(Color(UIColor.systemBackground))
        .frame(maxWidth: .infinity)
        .cornerRadius(16)
    }

    var productGridView: some View {
        ItemListView(viewModel: viewModel.itemSelectorViewModel)
            .frame(maxWidth: .infinity)
            .refreshable {
                await viewModel.itemSelectorViewModel.reload()
            }
    }
}

#if DEBUG
//#Preview {
//    NavigationStack {
//        PointOfSaleDashboardView(
//            viewModel: PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
//                                                     cardPresentPaymentService: CardPresentPaymentPreviewService(),
//                                                     orderService: POSOrderPreviewService()))
//    }
//}
#endif

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
                    cartView
                    Spacer()
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
        .sheet(isPresented: $viewModel.showsCardReaderSheet, content: {
            // Might be the only way unless we make the type conform to `Identifiable`
            if let alertType = viewModel.cardPresentPaymentAlertViewModel {
                PointOfSaleCardPresentPaymentAlert(alertType: alertType)
            } else {
                switch viewModel.cardPresentPaymentEvent {
                case .idle,
                        .show, // handled above
                        .showOnboarding:
                    Text(viewModel.cardPresentPaymentEvent.temporaryEventDescription)
                }
            }
        })
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

fileprivate extension CardPresentPaymentEvent {
    var temporaryEventDescription: String {
        switch self {
        case .idle:
            return "Idle"
        case .show:
            return "Event"
        case .showOnboarding(let onboardingViewModel):
            return "Onboarding: \(onboardingViewModel.state.reasonForAnalytics)" // This will only show the initial onboarding state
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PointOfSaleDashboardView(
            viewModel: PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                                     cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                     orderService: POSOrderPreviewService()))
    }
}
#endif

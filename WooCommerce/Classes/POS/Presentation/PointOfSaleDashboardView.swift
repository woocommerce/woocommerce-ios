import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel
    @ObservedObject private var cartViewModel: CartViewModel

    init(viewModel: PointOfSaleDashboardViewModel,
         totalsViewModel: TotalsViewModel,
         cartViewModel: CartViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel
    }

    private var isCartShown: Bool {
        !viewModel.itemListViewModel.isEmptyOrError
    }

    var body: some View {
        VStack {
            HStack {
                switch viewModel.orderStage {
                case .building:
                    GeometryReader { geometry in
                        HStack {
                            productListView
                            cartView
                                .renderedIf(isCartShown)
                                .frame(width: geometry.size.width * Constants.cartWidth)
                        }
                    }
                case .finalizing:
                    GeometryReader { geometry in
                        HStack {
                            if !viewModel.isTotalsViewFullScreen {
                                cartView
                                    .frame(width: geometry.size.width * Constants.cartWidth)
                                Spacer()
                            }
                            totalsView
                        }
                    }
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
        .sheet(isPresented: $totalsViewModel.showsCardReaderSheet, content: {
            // Might be the only way unless we make the type conform to `Identifiable`
            if let alertType = totalsViewModel.cardPresentPaymentAlertViewModel {
                PointOfSaleCardPresentPaymentAlert(alertType: alertType)
            } else {
                switch totalsViewModel.cardPresentPaymentEvent {
                case .idle,
                        .show, // handled above
                        .showOnboarding:
                    Text(totalsViewModel.cardPresentPaymentEvent.temporaryEventDescription)
                }
            }
        })
        .task {
            await viewModel.itemListViewModel.populatePointOfSaleItems()
        }
    }
}

private extension PointOfSaleDashboardView {
    enum Constants {
        // For the moment we're just considering landscape for the POS mode
        // https://github.com/woocommerce/woocommerce-ios/issues/13251
        static let cartWidth: CGFloat = 0.35
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var collapsedCartView: some View {
        CollapsedCartView()
    }

    var cartView: some View {
        CartView(viewModel: viewModel, cartViewModel: cartViewModel)
    }

    var totalsView: some View {
        TotalsView(viewModel: viewModel,
                   totalsViewModel: totalsViewModel,
                   cartViewModel: cartViewModel)
            .background(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity)
            .cornerRadius(16)
    }

    var productListView: some View {
        ItemListView(viewModel: viewModel.itemListViewModel)
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
    let totalsVM = TotalsViewModel(orderService: POSOrderPreviewService(),
                                   cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                   currencyFormatter: .init(currencySettings: .init()),
                                   paymentState: .acceptingCard,
                                   isSyncingOrder: false)
    let cartVM = CartViewModel()
    let posVM = PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                              orderService: POSOrderPreviewService(),
                                              currencyFormatter: .init(currencySettings: .init()),
                                              totalsViewModel: totalsVM,
                                              cartViewModel: cartVM)

    return NavigationStack {
        PointOfSaleDashboardView(viewModel: posVM, totalsViewModel: totalsVM, cartViewModel: cartVM)
    }
}
#endif

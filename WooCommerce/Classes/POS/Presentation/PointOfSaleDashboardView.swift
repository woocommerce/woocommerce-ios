import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = viewModel.totalsViewModel
    }

    var body: some View {
        VStack {
            HStack {
                switch viewModel.orderStage {
                case .building:
                    if viewModel.isCartCollapsed {
                        // 1. Initial state: Product list is visible and cart is collapsed
                        productListView
                            .frame(maxWidth: .infinity)
                        Spacer()
                        collapsedCartView
                    } else {
                        // 2. Products in cart: Both product list and cart are visible
                        GeometryReader { geometry in
                            HStack {
                                productListView
                                    .frame(width: geometry.size.width * Constants.productListWidth)
                                cartView
                                    .frame(width: geometry.size.width * Constants.cartWidth)
                            }
                        }
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
        .sheet(isPresented: $totalsViewModel.showsCardReaderSheet, content: {
            // Might be the only way unless we make the type conform to `Identifiable`
            if let alertType = totalsViewModel.cardPresentPaymentAlertViewModel {
                PointOfSaleCardPresentPaymentAlert(alertType: alertType)
            } else {
                switch totalsViewModel.cardPresentPaymentEvent {
                case .idle,
                        .show, // handled above
                        .showOnboarding:
                    Text(viewModel.totalsViewModel.cardPresentPaymentEvent.temporaryEventDescription)
                }
            }
        })
        .task {
            await viewModel.itemSelectorViewModel.populatePointOfSaleItems()
        }
    }
}

private extension PointOfSaleDashboardView {
    enum Constants {
        // TODO:
        // https://github.com/woocommerce/woocommerce-ios/issues/13240
        // The current design only accounts for landscape, switching to portrait
        // will need to be handled by resizing components and line-breaking for strings
        // and other elements
        static let productListWidth: CGFloat = 0.7
        static let cartWidth: CGFloat = 0.3
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
                                                     orderService: POSOrderPreviewService(),
                                                     currencyFormatter: .init(currencySettings: .init())))
    }
}
#endif

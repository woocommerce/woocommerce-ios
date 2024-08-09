import SwiftUI

struct PointOfSaleDashboardView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel
    @ObservedObject private var cartViewModel: CartViewModel
    @ObservedObject private var itemListViewModel: ItemListViewModel

    init(viewModel: PointOfSaleDashboardViewModel,
         totalsViewModel: TotalsViewModel,
         cartViewModel: CartViewModel,
         itemListViewModel: ItemListViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel
        self.itemListViewModel = itemListViewModel
    }

    private var isCartShown: Bool {
        !viewModel.itemListViewModel.isEmptyOrError
    }

    @State private var floatingSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if viewModel.isInitialLoading {
                PointOfSaleLoadingView()
                    .transition(.opacity)
            } else {
                contentView
                    .transition(.push(from: .top))

                POSFloatingControlView(viewModel: viewModel)
                    .shadow(color: Color.black.opacity(0.08), radius: 4)
                    .offset(x: Constants.floatingControlHorizontalOffset, y: -Constants.floatingControlVerticalOffset)
                    .trackSize(size: $floatingSize)
            }
        }
        .environment(\.floatingControlAreaSize,
                      CGSizeMake(floatingSize.width + Constants.floatingControlHorizontalOffset,
                                 floatingSize.height + Constants.floatingControlVerticalOffset))
        .environment(\.posBackgroundAppearance, totalsViewModel.paymentState != .processingPayment ? .primary : .secondary)
        .animation(.easeInOut, value: viewModel.isInitialLoading)
        .background(Color.posBackgroundGreyi3)
        .navigationBarBackButtonHidden(true)
        .posModal(isPresented: $totalsViewModel.showsCardReaderSheet) {
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
        }
        .posModal(isPresented: $itemListViewModel.showSimpleProductsModal) {
            SimpleProductsOnlyInformation(isPresented: $itemListViewModel.showSimpleProductsModal)
        }
        .posModal(isPresented: $viewModel.showExitPOSModal) {
            PointOfSaleExitPosAlertView(isPresented: $viewModel.showExitPOSModal)
            .frame(maxWidth: Constants.exitPOSSheetMaxWidth)
        }
        .task {
            await viewModel.itemListViewModel.populatePointOfSaleItems()
        }
    }

    private var contentView: some View {
        GeometryReader { geometry in
            HStack {
                if viewModel.orderStage == .building {
                    productListView
                        .transition(.move(edge: .leading))
                }

                if !viewModel.isTotalsViewFullScreen {
                    cartView
                        .frame(width: geometry.size.width * Constants.cartWidth)
                }

                if viewModel.orderStage == .finalizing {
                    totalsView
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.default, value: viewModel.orderStage)
            .animation(.default, value: viewModel.isTotalsViewFullScreen)
        }
    }
}

struct FloatingControlAreaSizeKey: EnvironmentKey {
    static let defaultValue = CGSize.zero
}

extension EnvironmentValues {
    var floatingControlAreaSize: CGSize {
        get { self[FloatingControlAreaSizeKey.self] }
        set { self[FloatingControlAreaSizeKey.self] = newValue }
    }
}

private extension PointOfSaleDashboardView {
    enum Constants {
        // For the moment we're just considering landscape for the POS mode
        // https://github.com/woocommerce/woocommerce-ios/issues/13251
        static let cartWidth: CGFloat = 0.35
        static let buttonImageAndTextSpacing: CGFloat = 12
        static let floatingControlHorizontalOffset: CGFloat = 24
        static let floatingControlVerticalOffset: CGFloat = 0
        static let exitPOSSheetMaxWidth: CGFloat = 900.0
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var cartView: some View {
        CartView(viewModel: viewModel, cartViewModel: cartViewModel)
    }

    var totalsView: some View {
        TotalsView(viewModel: viewModel,
                   totalsViewModel: totalsViewModel)
    }

    var productListView: some View {
        ItemListView(viewModel: itemListViewModel)
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
    let itemsListVM = ItemListViewModel(itemProvider: POSItemProviderPreview())
    let posVM = PointOfSaleDashboardViewModel(cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                              totalsViewModel: totalsVM,
                                              cartViewModel: cartVM,
                                              itemListViewModel: itemsListVM)

    return NavigationStack {
        PointOfSaleDashboardView(viewModel: posVM,
                                 totalsViewModel: totalsVM,
                                 cartViewModel: cartVM,
                                 itemListViewModel: itemsListVM)
    }
}
#endif

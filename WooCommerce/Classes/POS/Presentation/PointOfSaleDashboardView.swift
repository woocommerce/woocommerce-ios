import SwiftUI

struct PointOfSaleDashboardView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
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

    @State private var floatingSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            switch posModel.itemListState {
            case .initialLoading:
                PointOfSaleLoadingView()
                    .transition(.opacity)
                    .ignoresSafeArea()
            case .empty:
                PointOfSaleItemListEmptyView()
            case .error(let errorContents):
                PointOfSaleItemListErrorView(error: errorContents, onRetry: {
                    Task {
                        await posModel.loadInitialItems()
                    }
                })
            case .loading, .loaded:
                contentView
                    .accessibilitySortPriority(2)
            }

            POSFloatingControlView(viewModel: viewModel)
                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                .offset(x: Constants.floatingControlHorizontalOffset, y: -Constants.floatingControlVerticalOffset)
                .trackSize(size: $floatingSize)
                .accessibilitySortPriority(1)
                .renderedIf(posModel.itemListState != .initialLoading)

            POSConnectivityView()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.asymmetric(insertion: .push(from: .top), removal: .move(edge: .top)))
                .zIndex(1) /// Consistent animations not working without setting explicit zIndex
                .renderedIf(viewModel.showsConnectivityError)
        }
        .environment(\.floatingControlAreaSize,
                      CGSizeMake(floatingSize.width + Constants.floatingControlHorizontalOffset,
                                 floatingSize.height + Constants.floatingControlVerticalOffset))
        .environment(\.posBackgroundAppearance, posModel.paymentState != .processingPayment ? .primary : .secondary)
        .animation(.easeInOut, value: posModel.itemListState == .initialLoading)
        .animation(.easeInOut(duration: Constants.connectivityAnimationDuration), value: viewModel.showsConnectivityError)
        .background(Color.posPrimaryBackground)
        .navigationBarBackButtonHidden(true)
        .posModal(item: $posModel.cardPresentPaymentOnboardingViewModel, onDismiss: {
            posModel.cancelCardPaymentsOnboarding()
        }) { viewModel in
            paymentsOnboardingView(from: viewModel)
        }
        .posModal(item: $posModel.cardPresentPaymentAlertViewModel,
                  onDismiss: {
            posModel.cardPresentPaymentAlertViewModel?.onDismiss?()
        }) { alertType in
            PointOfSaleCardPresentPaymentAlert(alertType: alertType)
                .posInteractiveDismissDisabled(alertType.isDismissDisabled)
        }
        .posModal(isPresented: $viewModel.showExitPOSModal) {
            PointOfSaleExitPosAlertView(isPresented: $viewModel.showExitPOSModal)
            .frame(maxWidth: Constants.exitPOSSheetMaxWidth)
        }
        .posRootModal()
        .sheet(isPresented: $viewModel.showSupport) {
            supportForm
        }
        .task {
            await posModel.loadInitialItems()
        }
        .onChange(of: posModel.orderStage) { newValue in
            switch newValue {
            case .building:
                totalsViewModel.stopShowingTotalsView()
            case .finalizing:
                totalsViewModel.startShowingTotalsView()
            }
        }
    }

    private var contentView: some View {
        GeometryReader { geometry in
            HStack {
                if posModel.orderStage == .building {
                    productListView
                        .accessibilitySortPriority(2)
                        .transition(.move(edge: .leading))
                }

                if !posModel.paymentState.shownFullScreen {
                    cartView
                        .accessibilitySortPriority(1)
                        .frame(width: geometry.size.width * Constants.cartWidth)
                        .ignoresSafeArea(edges: .bottom)
                }

                if posModel.orderStage == .finalizing {
                    totalsView
                        .accessibilitySortPriority(2)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.default, value: posModel.orderStage)
            .animation(.default, value: posModel.paymentState.shownFullScreen)
        }
    }
}

private extension PointOfSaleDashboardView {
    var supportForm: some View {
        NavigationView {
            SupportForm(isPresented: $viewModel.showSupport,
                        viewModel: SupportFormViewModel(sourceTag: Constants.supportTag))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.supportDone) {
                        viewModel.showSupport = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    func paymentsOnboardingView(from onboardingViewModel: CardPresentPaymentsOnboardingViewModel) -> some View {
        onboardingViewModel.showSupport = {
            posModel.cancelCardPaymentsOnboarding()
            viewModel.showSupport = true
        }
        return PointOfSaleCardPresentPaymentOnboardingView(viewModel: .init(onboardingViewModel: onboardingViewModel,
                                                                            onDismissTap: {
            posModel.cancelCardPaymentsOnboarding()
        }))
        .onAppear {
            posModel.trackCardPaymentsOnboardingShown()
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
        static let floatingControlHorizontalOffset: CGFloat = 24
        static let floatingControlVerticalOffset: CGFloat = 0
        static let exitPOSSheetMaxWidth: CGFloat = 900.0
        static let supportTag = "origin:point-of-sale"
        static let connectivityAnimationDuration: CGFloat = 1.0
    }

    enum Localization {
        static let supportDone = NSLocalizedString(
            "pointOfSaleDashboard.support.done",
            value: "Done",
            comment: "Button to dismiss the support form from the POS dashboard."
        )
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var cartView: some View {
        CartView(viewModel: viewModel, cartViewModel: cartViewModel)
    }

    var totalsView: some View {
        TotalsView(viewModel: totalsViewModel)
    }

    var productListView: some View {
        ItemListView(viewModel: itemListViewModel)
    }
}

#if DEBUG
import class WooFoundation.MockAnalyticsPreview
import class WooFoundation.MockAnalyticsProviderPreview

#Preview {
    let posModel = PointOfSaleAggregateModel(
        itemProvider: POSItemProviderPreview(),
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderService: POSOrderPreviewService())
    let totalsVM = TotalsViewModel(posModel: posModel,
                                   cardPresentPaymentService: CardPresentPaymentPreviewService())
    let cartVM = CartViewModel(posModel: posModel)
    let itemsListVM = ItemListViewModel(posModel: posModel)
    let posVM = PointOfSaleDashboardViewModel(posModel: posModel,
                                              totalsViewModel: totalsVM,
                                              cartViewModel: cartVM,
                                              itemListViewModel: itemsListVM,
                                              connectivityObserver: POSConnectivityObserverPreview())

    return NavigationStack {
        PointOfSaleDashboardView(viewModel: posVM,
                                 totalsViewModel: totalsVM,
                                 cartViewModel: cartVM,
                                 itemListViewModel: itemsListVM)
    }
}
#endif

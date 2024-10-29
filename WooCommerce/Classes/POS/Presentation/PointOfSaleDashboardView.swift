import SwiftUI

struct PointOfSaleDashboardView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel
    @ObservedObject private var cartViewModel: CartViewModel
    @ObservedObject private var itemListViewModel: ItemListViewModel

    @ObservedObject private var posModel: PointOfSaleAggregateModel

    @State var showExitPOSModal: Bool = false
    @State var showSupport: Bool = false

    init(viewModel: PointOfSaleDashboardViewModel,
         totalsViewModel: TotalsViewModel,
         cartViewModel: CartViewModel,
         itemListViewModel: ItemListViewModel,
         posModel: PointOfSaleAggregateModel) {
        self.viewModel = viewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel
        self.itemListViewModel = itemListViewModel
        self.posModel = posModel
    }

    @State private var floatingSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if viewModel.isInitialLoading {
                PointOfSaleLoadingView()
                    .transition(.opacity)
                    .ignoresSafeArea()
            } else if viewModel.isError {
                let errorContents = viewModel.itemListViewModel.state.hasError
                PointOfSaleItemListErrorView(error: errorContents, onRetry: {
                    Task {
                        await viewModel.itemListViewModel.reload()
                    }
                })
            } else if viewModel.isEmpty {
                PointOfSaleItemListEmptyView()
            } else {
                contentView
                    .accessibilitySortPriority(2)
            }
            POSFloatingControlView(posModel: posModel,
                                   showExitPOSModal: $showExitPOSModal,
                                   showSupport: $showSupport)
                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                .offset(x: Constants.floatingControlHorizontalOffset, y: -Constants.floatingControlVerticalOffset)
                .trackSize(size: $floatingSize)
                .accessibilitySortPriority(1)
                .renderedIf(!viewModel.isInitialLoading)

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
        .animation(.easeInOut, value: viewModel.isInitialLoading)
        .animation(.easeInOut(duration: Constants.connectivityAnimationDuration), value: viewModel.showsConnectivityError)
        .background(Color.posPrimaryBackground)
        .navigationBarBackButtonHidden(true)
        .sheet(item: $totalsViewModel.cardPresentPaymentOnboardingViewModel) { viewModel in
            paymentsOnboardingView(from: viewModel)
        }
        .posModal(item: $totalsViewModel.cardPresentPaymentAlertViewModel,
                  onDismiss: {
            totalsViewModel.cardPresentPaymentAlertViewModel?.onDismiss?()
        }) { alertType in
            PointOfSaleCardPresentPaymentAlert(alertType: alertType)
                .posInteractiveDismissDisabled(alertType.isDismissDisabled)
        }
        .posModal(isPresented: $itemListViewModel.showSimpleProductsModal) {
            SimpleProductsOnlyInformation(isPresented: $itemListViewModel.showSimpleProductsModal)
        }
        .posModal(isPresented: $showExitPOSModal) {
            PointOfSaleExitPosAlertView(isPresented: $showExitPOSModal)
            .frame(maxWidth: Constants.exitPOSSheetMaxWidth)
        }
        .posRootModal()
        .sheet(isPresented: $showSupport) {
            supportForm
        }
        .task {
            await viewModel.itemListViewModel.loadInitialItems()
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

                if !viewModel.isTotalsViewFullScreen {
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
            .animation(.default, value: viewModel.isTotalsViewFullScreen)
        }
    }
}

private extension PointOfSaleDashboardView {
    var supportForm: some View {
        NavigationView {
            SupportForm(isPresented: $showSupport,
                        viewModel: SupportFormViewModel(sourceTag: Constants.supportTag))
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(Localization.supportDone) {
                        showSupport = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    func paymentsOnboardingView(from onboardingViewModel: CardPresentPaymentsOnboardingViewModel) -> some View {
        onboardingViewModel.showSupport = {
            totalsViewModel.cardPresentPaymentOnboardingViewModel = nil
            showSupport = true
        }
        onboardingViewModel.showURL = { url in
            totalsViewModel.cardPresentPaymentOnboardingURL = url
        }
        return NavigationStack {
            CardPresentPaymentsOnboardingView(viewModel: onboardingViewModel)
                .navigationBarTitleDisplayMode(.inline)
                .interactiveDismissDisabled()
                .toolbar {
                    Button(action: {
                        totalsViewModel.cardPresentPaymentOnboardingViewModel = nil
                    }) {
                        Text(Localization.cancelOnboarding)
                    }
                }
                .safariSheet(url: $totalsViewModel.cardPresentPaymentOnboardingURL)
                .onDisappear {
                    totalsViewModel.cancelOnboarding()
                }
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
        static let cancelOnboarding = NSLocalizedString(
            "pointOfSaleDashboard.payments.onboarding.cancel",
            value: "Cancel",
            comment: "Button to dismiss the payments onboarding sheet from the POS dashboard."
        )
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var cartView: some View {
        CartView(posModel: posModel,
                 viewModel: viewModel,
                 cartViewModel: cartViewModel)
    }

    var totalsView: some View {
        TotalsView(viewModel: totalsViewModel, posModel: posModel)
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
    let totalsVM = TotalsViewModel(
        posModel: posModel,
        currencyFormatter: .init(currencySettings: .init()))
    let cartVM = CartViewModel(analytics: MockAnalyticsPreview(),
                               posModel: posModel)
    let itemsListVM = ItemListViewModel(posModel: posModel)
    let posVM = PointOfSaleDashboardViewModel(
        posModel: posModel,
        totalsViewModel: totalsVM,
        cartViewModel: cartVM,
        itemListViewModel: itemsListVM,
        connectivityObserver: POSConnectivityObserverPreview())

    NavigationStack {
        PointOfSaleDashboardView(viewModel: posVM,
                                 totalsViewModel: totalsVM,
                                 cartViewModel: cartVM,
                                 itemListViewModel: itemsListVM,
                                 posModel: posModel)
    }
}
#endif

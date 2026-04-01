import SwiftUI
import WooFoundation

struct PointOfSaleDashboardView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posExternalViews) private var externalViews
    @Environment(\.dismiss) private var dismiss

    @State private var showExitPOSModal: Bool = false
    @State private var showSupport: Bool = false
    @State private var showDocumentation: Bool = false
    @State private var showSettings: Bool = false
    @State private var waitingTimeTracker: WaitingTimeTracker?

    @State private var navigationPath: [POSNavigationDestination] = []
    @State private var floatingSize: CGSize = .zero

    private var viewStateCoordinator: PointOfSaleViewStateCoordinator {
        posModel.viewStateCoordinatorForView
    }

    private var itemsViewState: ItemsViewState {
        switch viewStateCoordinator.selectedItemListType {
        case .products(let searching):
            if searching {
                return posModel.purchasableItemsSearchController.itemsViewState
            } else {
                return posModel.purchasableItemsController.itemsViewState
            }
        case .coupons(let searching):
            if searching {
                return posModel.couponsSearchController.itemsViewState
            } else {
                return posModel.couponsController.itemsViewState
            }
        }
    }

    // MARK: View State

    enum ViewState: Equatable {
        case loading(isCatalogSyncing: Bool = false)
        case ineligible(reason: POSIneligibleReason)
        case error(PointOfSaleErrorState)
        case content
        case unsupportedWidth
    }

    private var viewState: ViewState {
        PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: posModel.entryPointController.eligibilityState,
            itemsContainerState: itemsViewState.containerState,
            horizontalSizeClass: horizontalSizeClass
        )
    }

    var body: some View {
        @Bindable var posModel = posModel
        ZStack(alignment: .bottomLeading) {
            switch viewState {
            case .loading(let isCatalogSyncing):
                PointOfSaleLoadingView(
                    isCatalogSyncing: isCatalogSyncing,
                    onExit: { dismiss() }
                )
                    .transition(.opacity)
                    .ignoresSafeArea()
            case .ineligible(let reason):
                POSIneligibleView(reason: reason, onRefresh: {
                    try await posModel.entryPointController.refreshEligibility(reason: reason)
                })
                .frame(maxWidth: .infinity)
            case .error(let error):
                PointOfSaleItemListFullscreenErrorView(error: error, onAction: {
                    if error.errorType == .initialCatalogSyncError {
                        analytics.track(event: WooAnalyticsEvent.LocalCatalog.splashScreenRetryTapped())
                    }

                    Task {
                        switch viewStateCoordinator.selectedItemListType {
                        case .products(search: false):
                            await posModel.purchasableItemsController.loadItems(base: .root)
                        case .products(search: true):
                            await posModel.purchasableItemsSearchController.loadItems(base: .root)
                        case .coupons(search: false):
                            await posModel.couponsSearchController.loadItems(base: .root)
                        case .coupons(search: true):
                            await posModel.couponsSearchController.loadItems(base: .root)
                        }
                    }
                }, onExit: error.errorType == .initialCatalogSyncError ? { // TODO: WOOMOB-1692 remove specialisation of errors if possible
                    dismiss()
                } : nil)
            case .content:
                contentView
                    .accessibilitySortPriority(2)
            case .unsupportedWidth:
                PointOfSaleUnsupportedWidthView()
                    .transition(.opacity)
                    .ignoresSafeArea()
            }

            POSFloatingControlView(showExitPOSModal: $showExitPOSModal,
                                   showSupport: $showSupport,
                                   showDocumentation: $showDocumentation,
                                   showSettings: $showSettings)
            .offset(x: Constants.floatingControlHorizontalOffset, y: -Constants.floatingControlVerticalOffset)
            .padding(.bottom, Constants.floatingControlBottomPadding)
            .trackSize(size: $floatingSize)
            .accessibilitySortPriority(1)
            .renderedIf(viewState.showsFloatingControl)

            POSConnectivityView()
        }
        .environment(\.floatingControlAreaSize,
                      CGSizeMake(floatingSize.width + Constants.floatingControlHorizontalOffset,
                                 floatingSize.height + Constants.floatingControlVerticalOffset))
        .environment(\.posBackgroundAppearance, backgroundAppearance)
        .animation(.easeInOut, value: viewState == .loading())
        .background(Color.posSurface)
        .navigationBarBackButtonHidden(true)
        .posModal(item: $posModel.cardPresentPaymentOnboardingViewContainer, onDismiss: {
            posModel.cancelCardPaymentsOnboarding()
        }) { factory in
            paymentsOnboardingView(from: factory)
        }
        .posModal(item: $posModel.cardPresentPaymentAlertViewModel,
                  onDismiss: {
            posModel.cardPresentPaymentAlertViewModel?.onDismiss?()
        }) { alertType in
            PointOfSaleCardPresentPaymentAlert(alertType: alertType)
                .posInteractiveDismissDisabled(alertType.isDismissDisabled)
        }
        .posModal(isPresented: $showExitPOSModal) {
            PointOfSaleExitPosAlertView(isPresented: $showExitPOSModal)
            .frame(maxWidth: Constants.exitPOSSheetMaxWidth)
        }
        .posRootModal()
        .posSheet(isPresented: $showSupport) {
            supportForm
                .interactiveDismissDisabled(true)
        }
        .posSheet(isPresented: $showDocumentation) {
            documentationView
        }
        .posFullScreenCover(isPresented: $showSettings) {
            POSSettingsView(settingsController: posModel.settingsController)
        }
        .onChange(of: showSettings) { oldValue, newValue in
            guard !newValue, oldValue else { return }
            Task {
                await posModel.checkStaleSyncStatus()
            }
        }
        .onChange(of: posModel.entryPointController.eligibilityState) { oldValue, newValue in
            guard case .eligible = newValue, oldValue != newValue else { return }
            loadItemsWhenEligible()
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            trackTimeForInitialLoadingState()
            loadItemsWhenEligible()
        }
        .onChange(of: viewState) { oldValue, newValue in
            if newValue == .content && oldValue != newValue {
                trackElapsedTimeForInitialLoadingState()
            }
        }
    }

    private var navigationRouter: POSNavigationRouter {
        POSNavigationRouter(navigationPath: $navigationPath)
    }

    private var contentView: some View {
        @Bindable var viewStateCoordinator = viewStateCoordinator
        return GeometryReader { geometry in
            // Fixed widths ensure views don't resize during offset-based transitions.
            let productsWidth = geometry.size.width * (1 - Constants.cartWidth)
            let cartWidth = geometry.size.width * Constants.cartWidth
            let checkoutWidth = geometry.size.width * (1 - Constants.cartWidth)
            let dashboardWidth = productsWidth + cartWidth + checkoutWidth
            let dashboardOffset: CGFloat = posModel.orderStage == .building ? 0 : -productsWidth

            HStack(spacing: POSSpacing.none) {
                ItemListView(selectedItemListType: $viewStateCoordinator.selectedItemListType,
                             searchTerm: $viewStateCoordinator.searchTerm)
                    .frame(width: productsWidth)
                    .accessibilitySortPriority(posModel.orderStage == .building ? 2 : 0)
                    .allowsHitTesting(posModel.orderStage == .building)

                NavigationStack(path: $navigationPath) {
                    HStack(spacing: POSSpacing.none) {
                        if !posModel.paymentState.card.shownFullScreen
                            && posModel.paymentState.cash != .paymentSuccess {
                            CartView()
                                .frame(width: cartWidth)
                                .accessibilitySortPriority(1)
                        }

                        TotalsView()
                            .background(Color.posSurface)
                            .frame(width: posModel.paymentState.card.shownFullScreen
                                    || posModel.paymentState.cash == .paymentSuccess
                                   ? cartWidth + checkoutWidth
                                   : checkoutWidth)
                            .accessibilitySortPriority(posModel.orderStage == .finalizing ? 2 : 0)
                            .allowsHitTesting(posModel.orderStage == .finalizing)
                    }
                    .navigationDestination(for: POSNavigationDestination.self) { destination in
                        switch destination {
                        case .cashPayment(let orderTotal):
                            POSNavigationDestinationCashPaymentView(orderTotal: orderTotal)
                        case .emailReceipt:
                            POSNavigationDestinationEmailReceiptView()
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.posSurface)
                .frame(width: cartWidth + checkoutWidth)
            }
            .frame(width: dashboardWidth, alignment: .leading)
            .offset(x: dashboardOffset)
            .onChange(of: posModel.paymentState.cash) { _, newValue in
                if newValue == .collectingCash,
                   case .loaded(let totals) = posModel.orderState {
                    navigationRouter.pushCash(orderTotal: totals.orderTotal)
                }
            }
            .animation(.default, value: posModel.orderStage)
            .animation(.default, value: posModel.paymentState.card.shownFullScreen)
        }
        .ignoresSafeArea()
        .background(Color.posSurface.ignoresSafeArea())
        .environment(\.posNavigationRouter, navigationRouter)
    }

    private var backgroundAppearance: POSBackgroundAppearanceKey.Appearance {
        posModel.paymentState.card != .processingPayment ? .primary : .secondary
    }
}

private extension PointOfSaleDashboardView {
    var supportForm: some View {
        NavigationView {
            externalViews.createSupportFormView(isPresented: $showSupport, sourceTag: Constants.supportTag)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(Localization.supportCancel) {
                            showSupport = false
                        }
                    }
                }
                .navigationViewStyle(.stack)
        }
    }

    var documentationView: some View {
        SafariView(url: POSConstants.URLs.pointOfSaleDocumentation.asURL())
    }

    func paymentsOnboardingView(from factory: CardPresentPaymentOnboardingViewContainer) -> some View {
        factory.configuration.showSupport = { [weak posModel] in
            posModel?.cancelCardPaymentsOnboarding()
            showSupport = true
        }

        return PointOfSaleCardPresentPaymentOnboardingView(viewModel: .init(onboardingViewContainer: factory,
                                                                            onDismissTap: {
            posModel.cancelCardPaymentsOnboarding()
        }))
        .onAppear {
            posModel.trackCardPaymentsOnboardingShown()
        }
    }
}

private extension PointOfSaleDashboardView {
    func trackTimeForInitialLoadingState() {
        waitingTimeTracker = WaitingTimeTracker(trackScenario: .pointOfSaleLoaded)
    }

    func trackElapsedTimeForInitialLoadingState() {
        if let waitingTimeTracker {
            let syncStrategy = posModel.isLocalCatalogEligible ? "local_catalog" : "remote"
            let event = waitingTimeTracker.end(using: .milliseconds, additionalProperties: ["sync_strategy": syncStrategy])
            analytics.track(event: event)
            self.waitingTimeTracker = nil
        }
    }

    func loadItemsWhenEligible() {
        Task { @MainActor in
            await posModel.purchasableItemsController.loadItems(base: .root)
            await posModel.couponsController.loadItems(base: .root)
            await posModel.popularPurchasableItemsController.loadItems(base: .root)
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
        static let floatingControlBottomPadding: CGFloat = POSPadding.medium
        static let floatingControlHorizontalOffset: CGFloat = POSPadding.medium
        static let floatingControlVerticalOffset: CGFloat = 0
        static let exitPOSSheetMaxWidth: CGFloat = 900.0
        static let supportTag = "origin:point-of-sale"
    }

    enum Localization {
        static let supportCancel = NSLocalizedString(
            "pointOfSaleDashboard.support.cancel",
            value: "Cancel",
            comment: "Button to dismiss the support form from the POS dashboard."
        )
    }
}

#if DEBUG

#Preview("Container loading state") {
    return NavigationStack {
        PointOfSaleDashboardView()
            .environment(POSPreviewHelpers.makePreviewAggregateModel())
            .environmentObject(POSModalManager())
    }
}

#Preview("Content loading state") {
    let itemsController = PointOfSalePreviewItemsController()
    itemsController.itemsViewState = .init(containerState: .content, itemsStack: .init(root: .loading([]), itemStates: [:]))
    let posModel = POSPreviewHelpers.makePreviewAggregateModel(itemsController: itemsController)
    return NavigationStack {
        PointOfSaleDashboardView()
            .environment(posModel)
            .environmentObject(POSModalManager())
    }
}

#endif

import SwiftUI
import WooFoundation
import struct Yosemite.POSCustomAmount

struct PointOfSaleDashboardView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posCurrencyProvider) private var currencyProvider
    @Environment(\.posExternalViews) private var externalViews
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.dismiss) private var dismiss
    @Environment(\.keyboardObserver) private var keyboardObserver

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
            horizontalSizeClass: horizontalSizeClass,
            isPhonePrototypeEnabled: featureFlags.isFeatureFlagEnabled(.pointOfSalePhonePrototype)
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
            .renderedIf(viewState.showsFloatingControl && !isPhoneLayout)

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
        // Custom amount entry sheet — hosted here (not in `CartView`) because the entry trigger
        // lives in `ItemListView` and `CartView` is conditionally hidden during full-screen
        // payment / cash success. `onDismiss` routes every dismissal (swipe, back button, submit)
        // through `dismissCustomAmountSheet()` so `editingCustomAmount` is always cleared.
        .posFullScreenCover(
            isPresented: $posModel.isCustomAmountSheetPresented,
            onDismiss: { posModel.dismissCustomAmountSheet() }
        ) {
            AddCustomAmountView(
                isPresented: $posModel.isCustomAmountSheetPresented,
                currencySettings: currencyProvider.currencySettings,
                editing: posModel.editingCustomAmount,
                onSubmit: { customAmount in
                    let mode: WooAnalyticsEvent.PointOfSale.CustomAmountMode =
                        posModel.editingCustomAmount != nil ? .edit : .add
                    posModel.upsertCustomAmount(customAmount, mode: mode)
                }
            )
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
        .ignoresSafeArea(dashboardIgnoredSafeAreaRegions)
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

    @ViewBuilder
    private var contentView: some View {
        if isPhoneLayout {
            phoneContentView
        } else {
            tabletContentView
        }
    }

    private var isPhoneLayout: Bool {
        horizontalSizeClass == .compact && featureFlags.isFeatureFlagEnabled(.pointOfSalePhonePrototype)
    }

    @ViewBuilder
    private var phoneContentView: some View {
        @Bindable var viewStateCoordinator = viewStateCoordinator
        // Building stage: ItemListView (which carries its own NavigationStack for product drill-down)
        //                 + bottom Cart button — NO outer NavigationStack here, otherwise nested stacks
        //                 break .navigationDestination resolution for pushed views.
        // Finalizing stage: a fresh NavigationStack siblinged to (not wrapping) the items list, used
        //                   for pushing cash payment, email receipt, etc. via navigationPath.
        Group {
            switch posModel.orderStage {
            case .building:
                VStack(spacing: POSSpacing.none) {
                    ItemListView(selectedItemListType: $viewStateCoordinator.selectedItemListType,
                                 searchTerm: $viewStateCoordinator.searchTerm,
                                 trailingHeaderAccessory: AnyView(phoneOverflowMenu))
                    // Always shown — even with an empty cart — so the flow is always discoverable
                    // and the merchant has a consistent landmark at the bottom of the screen.
                    phoneCartButton
                }
            case .finalizing:
                NavigationStack(path: $navigationPath) {
                    phoneTotalsContainer
                        .navigationDestination(for: POSNavigationDestination.self) { destination in
                            switch destination {
                            case .cashPayment(let orderTotal):
                                POSNavigationDestinationCashPaymentView(orderTotal: orderTotal)
                            case .emailReceipt:
                                POSNavigationDestinationEmailReceiptView()
                            }
                        }
                }
                .environment(\.posNavigationRouter, navigationRouter)
            }
        }
        .onChange(of: posModel.paymentState.cash) { _, newValue in
            if newValue == .collectingCash,
               case .loaded(let totals) = posModel.orderState {
                navigationRouter.pushCash(orderTotal: totals.orderTotal)
            }
        }
        .onChange(of: posModel.orderStage) { _, newStage in
            // Dismiss the cart sheet automatically when checkout starts so the user lands
            // on the totals view rather than seeing cart fading away.
            if newStage == .finalizing {
                phoneShowingCart = false
            }
        }
        .posSheet(isPresented: $phoneShowingCart) {
            phoneCartSheetView
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
        .posFullScreenCover(isPresented: $phoneShowingBarcodeScannerSetup) {
            POSBarcodeScannerSetup(isPresented: $phoneShowingBarcodeScannerSetup, analytics: analytics)
        }
        .animation(.default, value: posModel.orderStage)
        .ignoresSafeArea()
        .background(Color.posSurface.ignoresSafeArea())
    }

    private var canExitFinalizingOnPhone: Bool {
        !CartViewHelper().shouldPreventCartEditing(
            orderState: posModel.orderState,
            paymentState: posModel.paymentState
        )
    }

    /// Wraps `TotalsView` with an in-screen `POSPageHeaderView` back button so the phone totals
    /// view follows the same pattern as cash payment, settings, and orders — instead of a
    /// system nav bar back button.
    private var phoneTotalsContainer: some View {
        VStack(spacing: 0) {
            POSPageHeaderView(
                title: Localization.phoneCheckoutTitle,
                backButtonConfiguration: .init(
                    state: canExitFinalizingOnPhone ? .enabled : .disabled,
                    action: { posModel.addMoreToCart() }
                )
            )
            TotalsView()
        }
        .background(Color.posSurface)
        .toolbar(.hidden, for: .navigationBar)
    }

    @State private var phoneShowingCart: Bool = false
    @State private var phoneShowOrders: Bool = false
    @State private var phoneShowingBarcodeScannerSetup: Bool = false
    @State private var phoneCartButtonPulse: Bool = false

    private var phoneOverflowMenu: some View {
        Menu {
            Button {
                analytics.track(.pointOfSaleExitMenuItemTapped)
                showExitPOSModal = true
            } label: {
                Label(Localization.phoneMenuExit, systemImage: "rectangle.portrait.and.arrow.forward")
            }
            Button {
                analytics.track(.pointOfSaleSettingsMenuItemTapped)
                showSettings = true
            } label: {
                Label(Localization.phoneMenuSettings, systemImage: "gearshape")
            }
            if featureFlags.isFeatureFlagEnabled(.pointOfSaleHistoricalOrdersi1) {
                Button {
                    analytics.track(event: WooAnalyticsEvent.PointOfSale.ordersMenuItemTapped())
                    phoneShowOrders = true
                } label: {
                    Label(Localization.phoneMenuOrders, systemImage: "text.document")
                }
            }
        } label: {
            Circle()
                .foregroundColor(.posSurfaceContainerLow)
                .overlay {
                    Image(systemName: "ellipsis")
                        .font(.posButtonSymbolSmall)
                        .foregroundColor(.posOnSurface)
                }
                .frame(width: POSHeaderLayoutConstants.minHeight, height: POSHeaderLayoutConstants.minHeight)
                .fixedSize()
        }
        .accessibilityIdentifier("pos-phone-overflow-menu")
        .posFullScreenCover(isPresented: $phoneShowOrders) {
            POSOrdersView(isPresented: $phoneShowOrders)
        }
    }

    /// Total cart size — products + coupons — used to drive the cart-button pulse so adding
    /// a coupon also gives visual feedback even though the displayed number stays products-only.
    private var phoneCartTotalCount: Int {
        posModel.cart.purchasableItems.count + posModel.cart.coupons.count
    }

    private var phoneCartButton: some View {
        Button {
            phoneShowingCart = true
        } label: {
            Text(String(format: Localization.phoneCart, posModel.cart.purchasableItems.count))
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                // Number flips smoothly between values instead of snapping.
                .contentTransition(.numericText())
                .animation(.snappy(duration: 0.25), value: posModel.cart.purchasableItems.count)
        }
        .buttonStyle(POSFilledButtonStyle(size: .normal))
        .padding(.horizontal, POSPadding.medium)
        .padding(.vertical, POSPadding.medium)
        // Quick pulse to confirm an item was added — only on count increases, so removing items
        // doesn't bounce the button distractingly. Watches the full cart count (products +
        // coupons) so adding a coupon also pulses, even though the displayed number is
        // products-only.
        .scaleEffect(phoneCartButtonPulse ? 1.04 : 1.0)
        .onChange(of: phoneCartTotalCount) { oldValue, newValue in
            guard newValue > oldValue else { return }
            withAnimation(.spring(response: 0.18, dampingFraction: 0.5)) {
                phoneCartButtonPulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    phoneCartButtonPulse = false
                }
            }
        }
        .accessibilityIdentifier("pos-phone-cart-button")
    }

    private var phoneCartSheetView: some View {
        // Drag indicator + swipe-down handle dismissal; an explicit close button isn't needed.
        // The barcode-scanner trigger is lifted to the dashboard level (via the closure here)
        // so it presents above the cart sheet rather than being torn down by POSSheet's
        // coverManager interaction.
        var cart = CartView()
        cart.onPresentBarcodeScannerSetup = {
            phoneShowingCart = false
            // Tiny delay so the cart sheet finishes dismissing before the cover presents,
            // otherwise iOS rejects the simultaneous transitions and nothing shows.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                phoneShowingBarcodeScannerSetup = true
            }
        }
        return cart
            .background(Color.posSurface)
    }

    private var tabletContentView: some View {
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

                        let totalsWidth = posModel.paymentState.card.shownFullScreen
                            || posModel.paymentState.cash == .paymentSuccess
                            ? cartWidth + checkoutWidth
                            : checkoutWidth

                        TotalsView()
                            .background(Color.posSurface)
                            .frame(width: totalsWidth)
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
        static let phoneCart = NSLocalizedString(
            "pointOfSaleDashboard.phone.cart",
            value: "Cart (%1$d)",
            comment: "Phone-only floating button to open the cart from the items list. %1$d is the cart item count."
        )
        static let phoneCheckoutTitle = NSLocalizedString(
            "pointOfSaleDashboard.phone.checkoutTitle",
            value: "Checkout",
            comment: "Phone-only header title shown above the totals view during checkout."
        )
        static let phoneMenuExit = NSLocalizedString(
            "pointOfSaleDashboard.phone.menu.exit",
            value: "Exit POS",
            comment: "Phone-only overflow menu item to exit Point of Sale."
        )
        static let phoneMenuSettings = NSLocalizedString(
            "pointOfSaleDashboard.phone.menu.settings",
            value: "Settings",
            comment: "Phone-only overflow menu item to open Point of Sale settings."
        )
        static let phoneMenuOrders = NSLocalizedString(
            "pointOfSaleDashboard.phone.menu.orders",
            value: "Orders",
            comment: "Phone-only overflow menu item to open the historical orders view."
        )
    }
}

private extension PointOfSaleDashboardView {
    /// Ignore keyboard safe area only for the full-size on-screen keyboard, so floating
    /// controls sit above the external keyboard's helper bar (pre-iOS 26 only; iOS 26 has no helper bar).
    var dashboardIgnoredSafeAreaRegions: SafeAreaRegions {
        if keyboardObserver.isFullSizeKeyboardVisible {
            return SafeAreaRegions.posContainerRegionToIgnore.union(.keyboard)
        } else {
            return .posContainerRegionToIgnore
        }
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

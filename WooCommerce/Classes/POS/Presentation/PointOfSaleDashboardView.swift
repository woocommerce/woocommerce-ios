import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleDashboardView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showExitPOSModal: Bool = false
    @State private var showSettings: Bool = false
    @State private var waitingTimeTracker: WaitingTimeTracker?

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
        case loading
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
            case .loading:
                PointOfSaleLoadingView()
                    .transition(.opacity)
                    .ignoresSafeArea()
            case .ineligible(let reason):
                POSIneligibleView(reason: reason, onRefresh: {
                    try await posModel.entryPointController.refreshEligibility(reason: reason)
                })
                .frame(maxWidth: .infinity)
            case .error(let error):
                PointOfSaleItemListFullscreenErrorView(error: error, onAction: {
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
                })
            case .content:
                contentView
                    .accessibilitySortPriority(2)
            case .unsupportedWidth:
                PointOfSaleUnsupportedWidthView()
                    .transition(.opacity)
                    .ignoresSafeArea()
            }

            POSFloatingControlView(showExitPOSModal: $showExitPOSModal,
                                   showSupport: .constant(false),
                                   showDocumentation: .constant(false),
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
        .animation(.easeInOut, value: viewState == .loading)
        .background(Color.posSurface)
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
        .posModal(isPresented: $showExitPOSModal) {
            PointOfSaleExitPosAlertView(isPresented: $showExitPOSModal)
            .frame(maxWidth: Constants.exitPOSSheetMaxWidth)
        }
        .posRootModal()
        .fullScreenCover(isPresented: $showSettings) {
            PointOfSaleSettingsView()
        }
        .onChange(of: posModel.entryPointController.eligibilityState) { oldValue, newValue in
            guard newValue == .eligible else { return }
            Task { @MainActor in
                await posModel.purchasableItemsController.loadItems(base: .root)
                await posModel.couponsController.loadItems(base: .root)
                await posModel.popularPurchasableItemsController.loadItems(base: .root)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onAppear {
            trackTimeForInitialLoadingState()
        }
        .onChange(of: viewState) { oldValue, newValue in
            if newValue == .content && oldValue != newValue {
                trackElapsedTimeForInitialLoadingState()
            }
        }
    }

    private var contentView: some View {
        @Bindable var viewStateCoordinator = viewStateCoordinator
        return GeometryReader { geometry in
            HStack(spacing: POSSpacing.none) {
                if posModel.orderStage == .building {
                    ItemListView(selectedItemListType: $viewStateCoordinator.selectedItemListType,
                                 searchTerm: $viewStateCoordinator.searchTerm)
                        .accessibilitySortPriority(2)
                        .transition(.move(edge: .leading))
                }

                if !posModel.paymentState.shownFullScreen {
                    CartView()
                        .accessibilitySortPriority(1)
                        .frame(width: geometry.size.width * Constants.cartWidth)
                }

                if posModel.orderStage == .finalizing {
                    TotalsView()
                        .accessibilitySortPriority(2)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.default, value: posModel.orderStage)
            .animation(.default, value: posModel.paymentState.shownFullScreen)
        }
    }

    private var backgroundAppearance: POSBackgroundAppearanceKey.Appearance {
        posModel.paymentState.card != .processingPayment ? .primary : .secondary
    }
}

@available(iOS 17.0, *)
private extension PointOfSaleDashboardView {
    func paymentsOnboardingView(from onboardingViewModel: CardPresentPaymentsOnboardingViewModel) -> some View {
        onboardingViewModel.showSupport = { [weak posModel] in
            posModel?.cancelCardPaymentsOnboarding()
            #warning("TODO: Support when onboarding view needs to be handled")
            //showSupport = true
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

@available(iOS 17.0, *)
private extension PointOfSaleDashboardView {
    func trackTimeForInitialLoadingState() {
        waitingTimeTracker = WaitingTimeTracker(trackScenario: .pointOfSaleLoaded)
    }

    func trackElapsedTimeForInitialLoadingState() {
        if let waitingTimeTracker {
            waitingTimeTracker.end(using: .milliseconds)
            self.waitingTimeTracker = nil
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

@available(iOS 17.0, *)
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
        static let supportDone = NSLocalizedString(
            "pointOfSaleDashboard.support.done",
            value: "Done",
            comment: "Button to dismiss the support form from the POS dashboard."
        )
    }
}

#if DEBUG

@available(iOS 17.0, *)
#Preview("Container loading state") {
    return NavigationStack {
        PointOfSaleDashboardView()
            .environment(POSPreviewHelpers.makePreviewAggregateModel())
            .environmentObject(POSModalManager())
    }
}

@available(iOS 17.0, *)
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


struct PointOfSaleSettingsView: View {
    enum SettingsSection: String, CaseIterable, Identifiable {
        case store = "Store"
        case productCatalog = "Product Catalog (TBD)"
        case payments = "Payments (TBD)"
        case hardware = "Hardware"
        case help = "Help"

        var id: String { rawValue }
    }

    @State private var showDocumentation = false
    @State private var showSupport = false

    var documentationDestinationView: some View {
        SafariView(url: WooConstants.URLs.pointOfSaleDocumentation.asURL())
            .navigationTitle("Documentation")
            .navigationBarTitleDisplayMode(.inline)
    }

    var supportDestinationView: some View {
        NavigationView {
            SupportForm(isPresented: $showSupport,
                        viewModel: SupportFormViewModel(
                            sourceTag: "origin:point-of-sale",
                            defaultSite: ServiceLocator.stores.sessionManager.defaultSite
                        )
            )
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showSupport = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    private var hardwareView: some View {
        Form {
            Section {
                HStack {
                    Text("Model")
                    Spacer()
                    Text("Wisepad 3")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Battery")
                    Spacer()
                    Text("87%")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Software Update")
                    Spacer()
                    Text("2024-07-01")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Button(action: {
                        // Handle
                    }) {
                        Text("Connect Card Reader")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                    Button(action: {
                        // Handle
                    }) {
                        Text("Software Update")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }

            } header: {
                Text("Card Readers")
            }
            Section {
                HStack {
                    Text("Model")
                    Spacer()
                    Text("Eyoyo")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Battery")
                    Spacer()
                    Text("68%")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Software Update")
                    Spacer()
                    Text("2024-07-01")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Barcode Scanner")
            }
        }
    }
    
    private var productCatalogView: some View {
        Form {
            Section {
                HStack {
                    Text("Last sync")
                    Spacer()
                    Text(Date().description)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Next scheduled sync")
                    Spacer()
                    Text(Date().description)
                        .foregroundColor(.secondary)
                }
                HStack {
                    Button(action: {
                        // Handle
                    }) {
                        Text("Sync Catalog")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }

            } header: {
                Text("Product Catalog")
            }
        }
    }

    private var storeDetailsView: some View {
        Form {
            Section {
                HStack {
                    Text("Store Name")
                    Spacer()
                    Text("My WooCommerce Store")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Address")
                    Spacer()
                    Text("123 Main Street, City, State 12345")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Phone")
                    Spacer()
                    Text("+1 (555) 123-4567")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Email")
                    Spacer()
                    Text("store@example.com")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Store Information")
            }
            Section {
                HStack {
                    Text("Store name")
                    Spacer()
                    Text("My WooCommerce Store")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Physical address")
                    Spacer()
                    Text("123 Main Street, City, State 12345")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Phone number")
                    Spacer()
                    Text("+1 (555) 123-4567")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Email")
                    Spacer()
                    Text("store@example.com")
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Refund & Returns Policy")
                    Spacer()
                    Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit...")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Receipt information (WC 10+)")
            }
        }
    }

    @State private var selectedSection: SettingsSection? = .store
    @State private var isSomeToggleEnabled = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $selectedSection) { section in
                Text(section.rawValue)
                    .tag(section)
            }
            .navigationTitle("Settings")
        } detail: {
            NavigationStack {
                VStack {
                    Group {
                        // Most likely this will end being a scroll view
                        if let section = selectedSection {
                            switch section {
                            case .store:
                                storeDetailsView
                            case .payments:
                                EmptyView()
                            case .productCatalog:
                                productCatalogView
                            case .hardware:
                                hardwareView
                            case .help:
                                Form {
                                    // Collapsable content, open modal, deeplinking, etc, ... based on case
                                    Button("Where are my products?") { /* ... */ }
                                    Button("Documentation") {
                                        // Problem if we attempt to present multiple sheets:
                                        // Currently, only presenting a single sheet is supported.
                                        // The next sheet will be presented when the currently presented sheet gets dismissed.
                                        showDocumentation = true
                                    }
                                    Button("Get Support") {
                                        showSupport = true
                                    }
                                }
                            }
                        }
                    }
                }
                
                NavigationLink(
                    destination: documentationDestinationView,
                    isActive: $showDocumentation
                ) {
                    EmptyView()
                }
                .hidden()
                NavigationLink(
                    destination: supportDestinationView,
                    isActive: $showSupport
                ) { EmptyView() }
                .hidden()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                             dismiss()
                         } label: {
                             Image(systemName: "xmark")
                         }
                    }
                }
            }
        }
    }
}

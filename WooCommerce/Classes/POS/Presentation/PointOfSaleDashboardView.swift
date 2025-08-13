import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleDashboardView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showExitPOSModal: Bool = false
    @State private var showSettingsViaFullScreenModal: Bool = false
    @State private var showSettingsViaPartialScreenModal: Bool = false
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
        case settings
        case content
        case unsupportedWidth
    }

    private var viewState: ViewState {
        PointOfSaleDashboardViewHelper.determineViewState(
            eligibilityState: posModel.entryPointController.eligibilityState,
            itemsContainerState: itemsViewState.containerState,
            horizontalSizeClass: horizontalSizeClass,
            viewStateCoordinator: viewStateCoordinator
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
            case .settings:
                settingsView
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
                                   showSettingsViaFullScreenModal: $showSettingsViaFullScreenModal,
                                   showSettingsViaPartialScreenModal: $showSettingsViaPartialScreenModal)
            .offset(x: Constants.floatingControlHorizontalOffset, y: -Constants.floatingControlVerticalOffset)
            .padding(.bottom, Constants.floatingControlBottomPadding)
            .trackSize(size: $floatingSize)
            .accessibilitySortPriority(1)
            .renderedIf(viewState.showsFloatingControl)

            POSConnectivityView()
            
            // Partial settings overlay
            if showSettingsViaPartialScreenModal {
                PointOfSalePartialSettingsView(isPresented: $showSettingsViaPartialScreenModal)
                    .transition(.move(edge: .leading))
            }
        }
        .environment(\.floatingControlAreaSize,
                      CGSizeMake(floatingSize.width + Constants.floatingControlHorizontalOffset,
                                 floatingSize.height + Constants.floatingControlVerticalOffset))
        .environment(\.posBackgroundAppearance, backgroundAppearance)
        .animation(.easeInOut, value: viewState == .loading)
        .animation(.easeInOut, value: showSettingsViaPartialScreenModal)
        .background(Color.posSurface)
        .navigationBarBackButtonHidden(true)
        .posModal2(item: $posModel.cardPresentPaymentOnboardingViewModel, onDismiss: {
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
        .posRootModal2() // Alternative POS Modal via PreferenceKeys system
        .fullScreenCover(isPresented: $showSettingsViaFullScreenModal) {
            // This needs to be duplicated, but modals like the card connection as .posModal will show BELOW the full screen cover
            // These won't be visible unless we dismiss fullScreenCover.
            PointOfSaleSettingsView()
// Commenting out this .posModal duplication as not needed for now,
// still does not work as the card connection flow is attached via .posModal to the PointOfSaleDashboardVew
// So it appears behind the PointOfSaleSettingsView, which has been presented as .fullScreenCover
//
//                .posModal(item: $posModel.cardPresentPaymentOnboardingViewModel, onDismiss: {
//                    posModel.cancelCardPaymentsOnboarding()
//                }) { viewModel in
//                    paymentsOnboardingView(from: viewModel)
//                }
//                .posModal(item: $posModel.cardPresentPaymentAlertViewModel,
//                          onDismiss: {
//                    posModel.cardPresentPaymentAlertViewModel?.onDismiss?()
//                }) { alertType in
//                    PointOfSaleCardPresentPaymentAlert(alertType: alertType)
//                        .posInteractiveDismissDisabled(alertType.isDismissDisabled)
//                }
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

    private var settingsView: some View {
        PointOfSaleSettingsView()
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

// Horizontal split: 30% (left) / 70% (right)
struct PointOfSaleSettingsView2: View {
    @Environment(\.dismiss) private var dismiss
    
    private enum Constants {
        static let leftRatio: CGFloat = 0.30
        static let rightRatio: CGFloat = 0.70
        static let leftBackground: Color = Color.posOutline.opacity(0.3)
        static let rightBackground: Color = Color.posSurface
    }

    var body: some View {
        NavigationStack {
            GeometryReader { geo in
                HStack(spacing: 0) {
                    VStack {
                        Text("30%")
                        //POSHeaderTitleView(title: "Store")
                        //POSHeaderTitleView(title: "Hardware")
                        //POSHeaderTitleView(title: "Help")
                    }
                    .frame(maxWidth: geo.size.width * Constants.leftRatio,
                           maxHeight: .infinity,
                           alignment: .center)
                    .background(Constants.leftBackground)
                    Text("70%")
                        .frame(maxWidth: geo.size.width * Constants.rightRatio,
                               maxHeight: .infinity,
                               alignment: .center)
                        .background(Constants.rightBackground)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.posSecondaryContainer)
                        }
                    }
                }
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarBackground(Color.clear, for: .navigationBar)
            }
        }
    }
}


@available(iOS 17.0, *)
struct PointOfSalePartialSettingsView: View {
    @Binding var isPresented: Bool
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    
    private enum Constants {
        static let leftRatio: CGFloat = 0.30
        static let rightRatio: CGFloat = 0.70
        static let leftBackground: Color = Color.posOutline //.opacity(0.8)
    }
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                // Left side - 30% with settings content
                VStack {
                    HStack {
                        Text("Settings")
                            .font(.title2)
                            .fontWeight(.semibold)
                        Spacer()
                        Button {
                            isPresented = false
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.posSecondaryContainer)
                        }
                    }
                    .padding()
                    
                    List {
                        Text("Store")
                        Text("Hardware") 
                        Text("Help")
                    }
                    .listStyle(.plain)
                    
                    Spacer()
                }
                .frame(maxWidth: geo.size.width * Constants.leftRatio,
                       maxHeight: .infinity,
                       alignment: .topLeading)
                .background(Constants.leftBackground)
                
                // Right side - 70% transparent
                Color.clear
                    .frame(maxWidth: geo.size.width * Constants.rightRatio,
                           maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
}


@available(iOS 17.0, *)
struct PointOfSaleSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    
    enum SettingsSection: String, CaseIterable, Identifiable {
        case store = "Store"
        case productCatalog = "Product Catalog (TBD)"
        case payments = "Payments (TBD)"
        case hardware = "Hardware"
        case configuration = "Configuration (TBD)"
        case help = "Help"

        var id: String { rawValue }
    }

    @State private var showDocumentation = false
    @State private var showSupport = false
    @State private var showTestModal = false

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
                        dismiss()
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
                    CardReaderConnectionStatusView()
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
                HStack {
                    Button(action: {
                        print("🟦 Test Modal3 button tapped")
                        showTestModal = true
                    }) {
                        Text("Test Modal3 (Global)")
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
                if #available(iOS 17.0, *) {
                    PointOfSaleBarcodeScannerSetup(isPresented: .constant(true))
                } else {
                    // Fallback on earlier versions
                    EmptyView()
                }
//                HStack {
//                    Text("Model")
//                    Spacer()
//                    Text("Eyoyo")
//                        .foregroundColor(.secondary)
//                }
//                HStack {
//                    Text("Battery")
//                    Spacer()
//                    Text("68%")
//                        .foregroundColor(.secondary)
//                }
//                HStack {
//                    Text("Software Update")
//                    Spacer()
//                    Text("2024-07-01")
//                        .foregroundColor(.secondary)
//                }
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
                            case .configuration:
                                EmptyView()
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
                            // #1
                            posModel.viewStateCoordinatorForView.hideSettings()
                            // #2
                            dismiss()
                         } label: {
                             Image(systemName: "xmark")
                         }
                    }
                }
                .posModal3(isPresented: $showTestModal) {
                    VStack {
                        Text("Minimal Test Modal")
                            .font(.title2)
                            .padding()
                        Button("Close") {
                            print("🟠 Close button tapped")
                            showTestModal = false
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                    .frame(width: 200, height: 150)
                    .background(Color.white)
                    .cornerRadius(12)
                }
            }
        }
    }
}

/// Represents a modal presentation request that can be communicated via PreferenceKey
struct POSModalRequest: Equatable {
    let id: UUID
    let content: AnyView
    let onDismiss: (() -> Void)?
    let allowsInteractiveDismissal: Bool
    
    init<Content: View>(
        id: UUID = UUID(),
        @ViewBuilder content: @escaping () -> Content,
        onDismiss: (() -> Void)? = nil,
        allowsInteractiveDismissal: Bool = true
    ) {
        self.id = id
        self.content = AnyView(content())
        self.onDismiss = onDismiss
        self.allowsInteractiveDismissal = allowsInteractiveDismissal
    }
    
    static func == (lhs: POSModalRequest, rhs: POSModalRequest) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - PreferenceKey Infrastructure

/// PreferenceKey for communicating modal presentation requests up the view hierarchy
struct POSModalPreferenceKey: PreferenceKey {
    static var defaultValue: POSModalRequest? = nil
    
    static func reduce(value: inout POSModalRequest?, nextValue: () -> POSModalRequest?) {
        // Take the first non-nil value (most recent modal request)
        if let next = nextValue() {
            value = next
        }
    }
}

// MARK: - Modal Presentation State Manager

/// Observable object to manage the current modal state at the app root level
@available(iOS 17.0, *)
@Observable class POSModal2Manager {
    private(set) var currentModal: POSModalRequest?
    private(set) var isPresented: Bool = false
    
    func present(_ modal: POSModalRequest) {
        currentModal = modal
        isPresented = true
    }
    
    func dismiss() {
        currentModal?.onDismiss?()
        currentModal = nil
        isPresented = false
    }
    
    var allowsInteractiveDismissal: Bool {
        currentModal?.allowsInteractiveDismissal ?? true
    }
    
    func getContent() -> AnyView {
        currentModal?.content ?? AnyView(EmptyView())
    }
}

// MARK: - Root Modal Presenter

/// View modifier that handles modal presentation at the app root level
@available(iOS 17.0, *)
struct POSRootModal2ViewModifier: ViewModifier {
    @State private var modalManager = POSModal2Manager()
    @State private var modalParentSize: CGSize = UIScreen.main.bounds.size
    @State private var lastModalRequest: POSModalRequest?
    
    private let animationDuration = Constants.animationDuration
    private let scaleTransitionAmount = Constants.scaleTransitionAmount
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: modalManager.isPresented ? 8 : 0)
                .disabled(modalManager.isPresented)
                .accessibilityElement(children: modalManager.isPresented ? .ignore : .contain)
                .onPreferenceChange(POSModalPreferenceKey.self) { modalRequest in
                    if let modalRequest = modalRequest {
                        if lastModalRequest?.id != modalRequest.id {
                            modalManager.present(modalRequest)
                            lastModalRequest = modalRequest
                        }
                    } else if lastModalRequest != nil {
                        // Modal request is now nil, so dismiss
                        modalManager.dismiss()
                        lastModalRequest = nil
                    }
                }
            
            if modalManager.isPresented {
                Color.posSurfaceDim.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        if modalManager.allowsInteractiveDismissal {
                            modalManager.dismiss()
                        }
                    }
                    .animation(nil, value: modalManager.isPresented)
                
                ZStack {
                    modalManager.getContent()
                        .environment(\.posModalParentSize, modalParentSize)
                        .background(Color.posSurfaceBright)
                        .cornerRadius(POSCornerRadiusStyle.extraLarge.value)
                        .posShadow(.large, cornerRadius: POSCornerRadiusStyle.extraLarge.value)
                        .padding()
                }
                .zIndex(1)
                .transition(.scale(scale: scaleTransitionAmount).combined(with: .opacity))
            }
        }
        .measureFrame { frame in
            updateModalParentSize(with: frame.size)
        }
        .animation(.easeInOut(duration: animationDuration), value: modalManager.isPresented)
        .environment(modalManager)
    }
    
    private func updateModalParentSize(with size: CGSize) {
        if size != modalParentSize && size != .zero {
            modalParentSize = size
        }
    }
}

@available(iOS 17.0, *)
private extension POSRootModal2ViewModifier {
    enum Constants {
        static let animationDuration: CGFloat = 0.25
        static let scaleTransitionAmount: CGFloat = 0.9
    }
}

// MARK: - Modal View Modifiers

/// View modifier for item-based modal presentation using PreferenceKey
@available(iOS 17.0, *)
struct POSModal2ViewModifier<Item: Identifiable & Equatable, ModalContent: View>: ViewModifier {
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let modalContent: (Item) -> ModalContent
    @State private var currentModalId: UUID?
    
    func body(content: Content) -> some View {
        content
            .preference(
                key: POSModalPreferenceKey.self,
                value: item != nil ? createModalRequest() : nil
            )
    }
    
    private func createModalRequest() -> POSModalRequest? {
        guard let item = item else { return nil }
        
        let modalId = UUID()
        currentModalId = modalId
        
        return POSModalRequest(
            id: modalId,
            content: {
                modalContent(item)
                    .animation(.default, value: self.item)
            },
            onDismiss: {
                // Internal dismissal (tap background) - defer state changes to avoid view update cycle issues
                Task { @MainActor in
                    self.onDismiss?()
                    self.item = nil
                    self.currentModalId = nil
                }
            }
        )
    }
}

/// View modifier for boolean-based modal presentation using PreferenceKey
@available(iOS 17.0, *)
struct POSModal2ViewModifierForBool<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let modalContent: () -> ModalContent
    @State private var currentModalId: UUID?
    
    func body(content: Content) -> some View {
        content
            .preference(
                key: POSModalPreferenceKey.self,
                value: isPresented ? createModalRequest() : nil
            )
    }
    
    private func createModalRequest() -> POSModalRequest? {
        guard isPresented else { return nil }
        
        let modalId = UUID()
        // Potential issue: This assignment triggers a concurrency warning: Modifying state during view update, this will cause undefined behavior.
        currentModalId = modalId

        return POSModalRequest(
            id: modalId,
            content: modalContent,
            onDismiss: {
                // Internal dismissal (tap background) - defer state changes to avoid view update cycle issues
                Task { @MainActor in
                    self.onDismiss?()
                    self.isPresented = false
                    self.currentModalId = nil
                }
            }
        )
    }
}

/// View modifier for interactive dismissal control
@available(iOS 17.0, *)
struct POSInteractiveDismiss2Modifier: ViewModifier {
    let disabled: Bool
    
    func body(content: Content) -> some View {
        content
        // Note: In the new system, interactive dismissal is controlled per-modal
        // This modifier would need to be enhanced to communicate back to the modal request
        // For now, we'll implement this as a preference as well
    }
}

// MARK: - View Extensions

@available(iOS 17.0, *)
extension View {
    /// Root modal presenter for the new PreferenceKey-based system
    /// Apply this at the application root level to enable posModal2 functionality
    func posRootModal2() -> some View {
        self.modifier(POSRootModal2ViewModifier())
    }
    
    /// Shows a modal view using the new PreferenceKey-based system
    /// This works from any view context, including views presented via fullScreenCover
    func posModal2<ModalContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        self.modifier(
            POSModal2ViewModifierForBool(
                isPresented: isPresented,
                onDismiss: onDismiss,
                modalContent: content
            )
        )
    }
    
    /// Shows a modal view using the new PreferenceKey-based system with item binding
    /// This works from any view context, including views presented via fullScreenCover
    func posModal2<Item: Identifiable & Equatable, ModalContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> ModalContent
    ) -> some View {
        self.modifier(
            POSModal2ViewModifier(
                item: item,
                onDismiss: onDismiss,
                modalContent: content
            )
        )
    }
    
    /// Controls interactive dismissal for posModal2 system
    func posInteractiveDismissDisabled2(_ disabled: Bool = true) -> some View {
        self.modifier(POSInteractiveDismiss2Modifier(disabled: disabled))
    }
}

// MARK: - Global Modal Manager System (posModal3)

/// Global singleton modal manager that works across all view contexts
@available(iOS 17.0, *)
@Observable class POSGlobalModalManager {
    static let shared = POSGlobalModalManager()

    private(set) var currentModal: POSModalRequest?
    private(set) var isPresented: Bool = false

    private init() {}

    func present(_ modal: POSModalRequest) {
        print("🟢 POSGlobalModalManager.present() called with modal id: \(modal.id)")
        currentModal = modal
        isPresented = true
        print("🟢 POSGlobalModalManager.present() completed - isPresented: \(isPresented)")
    }
    
    func dismiss() {
        print("🔴 POSGlobalModalManager.dismiss() called")
        currentModal?.onDismiss?()
        currentModal = nil
        isPresented = false
        print("🔴 POSGlobalModalManager.dismiss() completed - isPresented: \(isPresented)")
    }
    
    var allowsInteractiveDismissal: Bool {
        currentModal?.allowsInteractiveDismissal ?? true
    }
    
    func getContent() -> AnyView {
        currentModal?.content ?? AnyView(EmptyView())
    }
}

// MARK: - Global Modal View Modifiers

/// View modifier for boolean-based modal presentation using global manager
@available(iOS 17.0, *)
struct POSModal3ViewModifierForBool<ModalContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let modalContent: () -> ModalContent
    @State private var currentModalId: UUID?
    
    private let globalManager = POSGlobalModalManager.shared
    
    func body(content: Content) -> some View {
        content
            .onChange(of: isPresented) { oldValue, newValue in
                print("🔵 POSModal3ViewModifierForBool onChange: \(oldValue) -> \(newValue)")
                
                if newValue && currentModalId == nil {
                    print("🔵 Presenting modal...")
                    // Present modal
                    let modalId = UUID()
                    currentModalId = modalId
                    
                    let modalRequest = POSModalRequest(
                        id: modalId,
                        content: modalContent,
                        onDismiss: {
                            print("🔵 Modal onDismiss callback triggered")
                            self.onDismiss?()
                            self.isPresented = false
                            self.currentModalId = nil
                        },
                        allowsInteractiveDismissal: true
                    )
                    
                    globalManager.present(modalRequest)
                } else if !newValue && currentModalId != nil {
                    print("🔵 Dismissing modal...")
                    // Dismiss modal
                    globalManager.dismiss()
                    currentModalId = nil
                }
            }
    }
}

/// View modifier for item-based modal presentation using global manager
@available(iOS 17.0, *)
struct POSModal3ViewModifier<Item: Identifiable & Equatable, ModalContent: View>: ViewModifier {
    @Binding var item: Item?
    let onDismiss: (() -> Void)?
    let modalContent: (Item) -> ModalContent
    @State private var currentModalId: UUID?
    
    private let globalManager = POSGlobalModalManager.shared
    
    func body(content: Content) -> some View {
        content
            .onChange(of: item) { oldValue, newValue in
                Task { @MainActor in
                    if let newValue = newValue, currentModalId == nil {
                        // Present modal
                        let modalId = UUID()
                        currentModalId = modalId
                        
                        let modalRequest = POSModalRequest(
                            id: modalId,
                            content: {
                                modalContent(newValue)
                                    .animation(.default, value: self.item)
                            },
                            onDismiss: {
                                Task { @MainActor in
                                    self.onDismiss?()
                                    self.item = nil
                                    self.currentModalId = nil
                                }
                            }
                        )
                        
                        globalManager.present(modalRequest)
                    } else if newValue == nil && currentModalId != nil {
                        // Dismiss modal
                        globalManager.dismiss()
                        currentModalId = nil
                    }
                }
            }
    }
}

// MARK: - Global Root Modal Handler

/// Root modal handler that observes the global manager and presents modals above all content
@available(iOS 17.0, *)
struct POSRootModal3ViewModifier: ViewModifier {
    @State private var modalParentSize: CGSize = UIScreen.main.bounds.size
    @State private var isModalPresented: Bool = false
    @State private var modalContent: AnyView = AnyView(EmptyView())
    @State private var allowsInteractiveDismissal: Bool = true
    @State private var cachedModalId: UUID?
    
    private let globalManager = POSGlobalModalManager.shared
    private let animationDuration: CGFloat = 0.25
    private let scaleTransitionAmount: CGFloat = 0.9
    
    func body(content: Content) -> some View {
        ZStack {
            content
                .blur(radius: isModalPresented ? 8 : 0)
                .disabled(isModalPresented)
                .accessibilityElement(children: isModalPresented ? .ignore : .contain)
                .onReceive(Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()) { _ in
                    // Poll the global manager state to avoid direct @Observable binding issues
                    // Reduced frequency from 0.01s to 0.1s to prevent excessive updates
                    let managerPresented = globalManager.isPresented
                    let currentModalId = globalManager.currentModal?.id
                    
                    if managerPresented != isModalPresented {
                        print("🟡 Root modal state change: \(isModalPresented) -> \(managerPresented)")
                        isModalPresented = managerPresented
                        allowsInteractiveDismissal = globalManager.allowsInteractiveDismissal
                        
                        // Only update content if modal ID changed to prevent unnecessary re-renders
                        if currentModalId != cachedModalId {
                            print("🟡 Modal content updated for ID: \(currentModalId?.uuidString ?? "nil")")
                            modalContent = globalManager.getContent()
                            cachedModalId = currentModalId
                        }
                    } else if currentModalId != cachedModalId {
                        // Modal ID changed but presentation state didn't - update content
                        print("🟡 Modal content changed for same presentation state")
                        modalContent = globalManager.getContent()
                        cachedModalId = currentModalId
                        allowsInteractiveDismissal = globalManager.allowsInteractiveDismissal
                    }
                }
            
            if isModalPresented {
                Color.posSurfaceDim.opacity(0.8)
                    .edgesIgnoringSafeArea(.all)
                    .onTapGesture {
                        if allowsInteractiveDismissal {
                            print("🟡 Background tap - dismissing modal")
                            globalManager.dismiss()
                        }
                    }
                    .animation(nil, value: isModalPresented)
                
                ZStack {
                    modalContent
                        .environment(\.posModalParentSize, modalParentSize)
                        .background(Color.posSurfaceBright)
                        .cornerRadius(POSCornerRadiusStyle.extraLarge.value)
                        .posShadow(.large, cornerRadius: POSCornerRadiusStyle.extraLarge.value)
                        .padding()
                }
                .zIndex(1)
                .transition(.scale(scale: scaleTransitionAmount).combined(with: .opacity))
            }
        }
        .measureFrame { frame in
            updateModalParentSize(with: frame.size)
        }
        .animation(.easeInOut(duration: animationDuration), value: isModalPresented)
    }
    
    private func updateModalParentSize(with size: CGSize) {
        if size != modalParentSize && size != .zero {
            modalParentSize = size
        }
    }
}

// MARK: - Global Modal View Extensions

@available(iOS 17.0, *)
extension View {
    /// Root modal presenter for the global modal system
    /// Apply this at the highest level (PointOfSaleEntryPointView) to enable posModal3 functionality
    func posRootModal3() -> some View {
        self.modifier(POSRootModal3ViewModifier())
    }
    
    /// Shows a modal view using the global modal system
    /// This works from any view context, including fullScreenCover, sheets, NavigationView, etc.
    func posModal3<ModalContent: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> ModalContent
    ) -> some View {
        self.modifier(
            POSModal3ViewModifierForBool(
                isPresented: isPresented,
                onDismiss: onDismiss,
                modalContent: content
            )
        )
    }
    
    /// Shows a modal view using the global modal system with item binding
    /// This works from any view context, including fullScreenCover, sheets, NavigationView, etc.
    func posModal3<Item: Identifiable & Equatable, ModalContent: View>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> ModalContent
    ) -> some View {
        self.modifier(
            POSModal3ViewModifier(
                item: item,
                onDismiss: onDismiss,
                modalContent: content
            )
        )
    }
}

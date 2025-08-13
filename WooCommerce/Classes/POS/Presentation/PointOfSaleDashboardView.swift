import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleDashboardView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showExitPOSModal: Bool = false
    @State private var showSupport: Bool = false
    @State private var showDocumentation: Bool = false
    @State private var showTestFullscreenOverlay: Bool = false
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
                                   showSupport: $showSupport,
                                   showDocumentation: $showDocumentation,
                                   showTestFullscreenOverlay: $showTestFullscreenOverlay)
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
        .posSheet(isPresented: $showSupport) {
            supportForm
                .interactiveDismissDisabled(true)
        }
        .posSheet(isPresented: $showDocumentation) {
            documentationView
        }
        .posFullscreenOverlay(isPresented: $showTestFullscreenOverlay) {
            testFullscreenOverlayContent
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
    var supportForm: some View {
        NavigationView {
            SupportForm(isPresented: $showSupport,
                        viewModel: SupportFormViewModel(sourceTag: Constants.supportTag,
                                                        defaultSite: ServiceLocator.stores.sessionManager.defaultSite))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(Localization.supportCancel) {
                        showSupport = false
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    var documentationView: some View {
        SafariView(url: WooConstants.URLs.pointOfSaleDocumentation.asURL())
    }
    
    var testFullscreenOverlayContent: some View {
        TestFullscreenOverlayView()
    }

    func paymentsOnboardingView(from onboardingViewModel: CardPresentPaymentsOnboardingViewModel) -> some View {
        onboardingViewModel.showSupport = { [weak posModel] in
            posModel?.cancelCardPaymentsOnboarding()
            showSupport = true
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
        static let supportCancel = NSLocalizedString(
            "pointOfSaleDashboard.support.cancel",
            value: "Cancel",
            comment: "Button to dismiss the support form from the POS dashboard."
        )
    }
}

// MARK: - Test Fullscreen Overlay View

@available(iOS 17.0, *)
struct TestFullscreenOverlayView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.parentModalManager) private var parentModalManager
    @EnvironmentObject private var modalManager: POSModalManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Test Fullscreen Overlay")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Test modal coordination across fullscreen boundaries")
                    .multilineTextAlignment(.center)
                    .padding()
                
                VStack(spacing: 15) {
                    Button("Test Modal (Simple Demo)") {
                        // Use the modal system directly
                        modalManager.present(onDismiss: {
                            print("Modal dismissed via fullscreen modal system")
                        }) {
                            testModalContent
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    Button("Test Barcode Scanner Setup") {
                        // Present PointOfSaleBarcodeScannerSetup using fullscreen modal system
                        modalManager.present(onDismiss: {
                            print("Barcode scanner setup dismissed")
                        }) {
                            barcodeScannerSetupContent
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Text("↑ These modals should appear ABOVE this fullscreen view")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Fullscreen Test")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .posRootModal()  // Add modal presentation layer for fullscreen content
    }
    
    private var testModalContent: some View {
        VStack {
            Text("Success! 🎉")
                .font(.title)
                .fontWeight(.bold)
                .padding()
            
            Text("This modal is displayed using the parent's modal system")
                .multilineTextAlignment(.center)
                .padding()
            
            Text("It appears ABOVE the fullscreen overlay!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding()
            
            Button("Close") {
                modalManager.dismiss()
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .frame(maxWidth: 400)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    @State private var barcodeScannerIsPresented = false
    
    private var barcodeScannerSetupContent: some View {
        Group {
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.pointOfSaleBarcodeScanningi2) {
                // Create a wrapper that handles the binding properly
                BarcodeScannerSetupWrapper(onDismiss: {
                    modalManager.dismiss()
                })
            } else {
                VStack {
                    Text("Barcode Scanner Setup")
                        .font(.title)
                        .fontWeight(.bold)
                        .padding()
                    
                    Text("This would be the PointOfSaleBarcodeScannerSetup view")
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Text("Presented ABOVE the fullscreen overlay via parent modal system!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button("Close") {
                        modalManager.dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .padding()
                }
                .frame(maxWidth: 500)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
        }
    }
}

@available(iOS 17.0, *)
struct BarcodeScannerSetupWrapper: View {
    let onDismiss: () -> Void
    @State private var isPresented = true
    
    var body: some View {
        PointOfSaleBarcodeScannerSetup(isPresented: $isPresented)
            .onChange(of: isPresented) { _, newValue in
                if !newValue {
                    onDismiss()
                }
            }
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

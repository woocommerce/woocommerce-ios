import SwiftUI

@available(iOS 17.0, *)
struct PointOfSaleDashboardView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showExitPOSModal: Bool = false
    @State private var showSupport: Bool = false
    @State private var showDocumentation: Bool = false

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

    var body: some View {
        @Bindable var posModel = posModel
        ZStack(alignment: .bottomLeading) {
            if case .regular = horizontalSizeClass {
                switch itemsViewState.containerState {
                case .loading:
                    PointOfSaleLoadingView()
                        .transition(.opacity)
                        .ignoresSafeArea()
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
                }
            } else {
                PointOfSaleUnsupportedWidthView()
                    .transition(.opacity)
                    .ignoresSafeArea()
            }

            POSFloatingControlView(showExitPOSModal: $showExitPOSModal,
                                   showSupport: $showSupport,
                                   showDocumentation: $showDocumentation)
            .offset(x: Constants.floatingControlHorizontalOffset, y: -Constants.floatingControlVerticalOffset)
            .padding(.bottom, Constants.floatingControlBottomPadding)
            .trackSize(size: $floatingSize)
            .accessibilitySortPriority(1)
            .renderedIf(itemsViewState.containerState != .loading)

            POSConnectivityView()
        }
        .environment(\.floatingControlAreaSize,
                      CGSizeMake(floatingSize.width + Constants.floatingControlHorizontalOffset,
                                 floatingSize.height + Constants.floatingControlVerticalOffset))
        .environment(\.posBackgroundAppearance, posModel.paymentState != .card(.processingPayment) ? .primary : .secondary)
        .animation(.easeInOut, value: itemsViewState.containerState == .loading)
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
        .sheet(isPresented: $showSupport) {
            supportForm
                .interactiveDismissDisabled(true)
        }
        .sheet(isPresented: $showDocumentation) {
            documentationView
        }
        .task {
            await posModel.purchasableItemsController.loadItems(base: .root)
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.enableCouponsInPointOfSale) {
                await posModel.couponsController.loadItems(base: .root)
            }
            if ServiceLocator.featureFlagService.isFeatureFlagEnabled(.searchProductsInPOS),
               ServiceLocator.featureFlagService.isFeatureFlagEnabled(.searchProductsInPOSPt2PopularProducts) {
                await posModel.loadPopularItems(type: .product)
            }
        }
        .ignoresSafeArea(.keyboard)
    }

    private var contentView: some View {
        @Bindable var viewStateCoordinator = viewStateCoordinator
        return GeometryReader { geometry in
            HStack {
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
}

@available(iOS 17.0, *)
private extension PointOfSaleDashboardView {
    var supportForm: some View {
        NavigationView {
            SupportForm(isPresented: $showSupport,
                        viewModel: SupportFormViewModel(sourceTag: Constants.supportTag,
                                                        defaultSite: ServiceLocator.stores.sessionManager.defaultSite))
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

    var documentationView: some View {
        SafariView(url: WooConstants.URLs.pointOfSaleDocumentation.asURL())
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

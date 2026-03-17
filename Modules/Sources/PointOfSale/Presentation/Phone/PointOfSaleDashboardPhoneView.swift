import SwiftUI

struct PointOfSaleDashboardPhoneView: View {
    @Environment(PointOfSaleAggregateModel.self) private var posModel
    @Environment(POSPaymentModel.self) private var paymentModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.posAnalytics) private var analytics
    @Environment(\.posFeatureFlags) private var featureFlags
    @Environment(\.posBookingsEligible) private var isBookingsEligible

    let viewState: PointOfSaleDashboardView.ViewState
    let menuPresenter: POSMenuPresenter

    @State private var isCartPresented: Bool
    @State private var isShowingCheckout = false

    init(viewState: PointOfSaleDashboardView.ViewState,
         menuPresenter: POSMenuPresenter = POSMenuPresenter(),
         isCartPresented: Bool = false) {
        self.viewState = viewState
        self.menuPresenter = menuPresenter
        self._isCartPresented = State(initialValue: isCartPresented)
    }

    var body: some View {
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
                Task {
                    await posModel.purchasableItemsController.loadItems(base: .root)
                }
            }, onExit: error.errorType == .initialCatalogSyncError ? {
                dismiss()
            } : nil)
        case .content:
            phoneContentView
        case .unsupportedWidth:
            EmptyView()
        }
    }

    private var phoneContentView: some View {
        ZStack {
            if !isCartPresented {
                productsScreen
            }

            if isCartPresented {
                cartSheetContent
                    .transition(.move(edge: .bottom))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.86), value: isCartPresented)
        .onAppear {
            if posModel.orderStage == .finalizing {
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    isCartPresented = true
                    isShowingCheckout = true
                }
            }
        }
        .onChange(of: posModel.orderStage) { oldStage, newStage in
            switch newStage {
            case .finalizing:
                isShowingCheckout = true
            case .building:
                if oldStage == .finalizing {
                    isShowingCheckout = false
                    isCartPresented = false
                }
            }
        }
    }

    // MARK: - Products Screen

    private var productsScreen: some View {
        @Bindable var viewStateCoordinator = posModel.viewStateCoordinatorForView
        return ZStack(alignment: .bottom) {
            VStack(spacing: POSSpacing.none) {
                ItemListView(
                    selectedItemListType: $viewStateCoordinator.selectedItemListType,
                    searchTerm: $viewStateCoordinator.searchTerm
                )
                .environment(\.posHeaderLeadingContent, AnyView(phoneMenuButton))
            }

            POSCartButton(
                itemCount: posModel.cart.purchasableItems.count + posModel.cart.coupons.count,
                action: { isCartPresented = true }
            )
        }
        .background(Color.posSurface)
    }

    private var phoneMenuButton: some View {
        Menu {
            menuPresenter.menuOptions(
                featureFlags: featureFlags,
                isBookingsEligible: isBookingsEligible,
                analytics: analytics
            )
        } label: {
            Image(systemName: "ellipsis")
                .font(.posBodyMediumBold)
                .foregroundStyle(Color.posOnSurface)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityIdentifier("pos-phone-menu-button")
    }

    // MARK: - Cart Sheet Content

    private var cartSheetContent: some View {
        ZStack {
            Color.posSurface
                .ignoresSafeArea()

            if isShowingCheckout {
                totalsContent
                    .transition(.move(edge: .trailing))
            } else {
                cartListView
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.default, value: isShowingCheckout)
    }

    private var totalsContent: some View {
        VStack(spacing: POSSpacing.none) {
            if !paymentModel.paymentState.shownFullScreen {
                POSPageHeaderView(
                    title: "",
                    backButtonConfiguration: .init(
                        state: .enabled,
                        action: {
                            isShowingCheckout = false
                            posModel.addMoreToCart()
                        }
                    )
                )
            }
            TotalsView()
        }
    }

    private var cartListView: some View {
        CartView()
            .posHeaderBackButtonIcon(systemName: "xmark")
            .environment(\.posHeaderBackButtonConfiguration,
                          POSPageHeaderBackButtonConfiguration(
                            state: .enabled,
                            action: { isCartPresented = false }
                          ))
    }
}

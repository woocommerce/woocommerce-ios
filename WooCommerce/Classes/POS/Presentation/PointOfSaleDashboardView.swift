import SwiftUI

struct PointOfSaleDashboardView: View {
    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel
    private let cartViewModel: CartViewModel

    @ObservedObject private var posModel: PointOfSaleAggregateModel

    @State var showExitPOSModal: Bool = false
    @State var showSupport: Bool = false
    @State private var itemListState: PointOfSaleItemListState = .initialLoading

    private let itemsService: POSItemsService
    @State private var allItems: [any POSDisplayableItem] = []
    private var currentPage: Int = Constants.initialPage

    init(viewModel: PointOfSaleDashboardViewModel,
         totalsViewModel: TotalsViewModel,
         cartViewModel: CartViewModel,
         posModel: PointOfSaleAggregateModel,
         itemsService: POSItemsService) {
        self.viewModel = viewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel
        self.posModel = posModel
        self.itemsService = itemsService
    }

    @State private var floatingSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            switch itemListState {
            case .initialLoading:
                PointOfSaleLoadingView()
                    .transition(.opacity)
                    .ignoresSafeArea()
            case .error(let errorContents):
                PointOfSaleItemListErrorView(error: errorContents, onRetry: {
                    Task {
                        await reloadItems()
                    }
                })
            case .empty:
                PointOfSaleItemListEmptyView()
            case .loading, .loaded:
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
                .renderedIf(itemListState != .initialLoading)

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
        .animation(.easeInOut, value: itemListState == .initialLoading)
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
        .posModal(isPresented: $showExitPOSModal) {
            PointOfSaleExitPosAlertView(isPresented: $showExitPOSModal)
            .frame(maxWidth: Constants.exitPOSSheetMaxWidth)
        }
        .posRootModal()
        .sheet(isPresented: $showSupport) {
            supportForm
        }
        .task {
            await loadInitialItems()
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

                if !posModel.paymentState.cardHasBeenTapped {
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
            .animation(.default, value: posModel.paymentState.cardHasBeenTapped)
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

private extension PointOfSaleDashboardView {
    @MainActor
    func loadInitialItems() async {
        do {
            itemListState = .initialLoading
            try await fetchItems(pageNumber: 1)
        } catch {
            itemListState = .error(PointOfSaleErrorState.errorOnLoadingProducts())
        }
    }

    @MainActor
    func loadNextItems() async {
        // TODO: Optimize API calls. gh-14186
        // If there are no more pages to fetch, we can avoid the next call.
        let nextPage = currentPage + 1
        await loadItems(pageNumber: nextPage)
    }

    @MainActor
    func loadItems(pageNumber: Int) async {
        do {
            itemListState = .loading(allItems)
            try await fetchItems(pageNumber: pageNumber)
        } catch {
            itemListState = .error(PointOfSaleErrorState.errorOnLoadingProducts())
        }
    }

    @MainActor
    func fetchItems(pageNumber: Int) async throws {
        let newItems = try await itemsService.fetchItems(pageNumber: pageNumber)
        let uniqueNewItems = newItems
            .filter { newItem in
                !allItems.contains(where: { $0.id == newItem.itemID })
            }
            .compactMap(createPOSDisplayableItem(for:))

        allItems.append(contentsOf: uniqueNewItems)

        if allItems.count == 0 {
            itemListState = .empty
        } else {
            itemListState = .loaded(allItems)
        }
    }

    @MainActor
    func reloadItems() async {
        removeAllItems()
        await loadItems(pageNumber: 1)
    }

    func removeAllItems() {
        allItems.removeAll()
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

        static let initialPage: Int = 1
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
        ItemListView(itemListState: $itemListState,
                     loadNextItems: loadNextItems,
                     reloadItems: reloadItems)
    }
}

#if DEBUG
import class WooFoundation.MockAnalyticsPreview
import class WooFoundation.MockAnalyticsProviderPreview

#Preview {

    let posModel = PointOfSaleAggregateModel(
        cardPresentPaymentService: CardPresentPaymentPreviewService(),
        orderService: POSOrderPreviewService(),
        analytics: MockAnalyticsPreview())
    let totalsVM = TotalsViewModel(
        posModel: posModel,
        currencyFormatter: .init(currencySettings: .init()))
    let cartVM = CartViewModel(analytics: MockAnalyticsPreview(),
                               posModel: posModel)
    let posVM = PointOfSaleDashboardViewModel(
        posModel: posModel,
        connectivityObserver: POSConnectivityObserverPreview())

    NavigationStack {
        PointOfSaleDashboardView(viewModel: posVM,
                                 totalsViewModel: totalsVM,
                                 cartViewModel: cartVM,
                                 posModel: posModel,
                                 itemsService: POSItemsService(itemProvider: POSItemProviderPreview()))
    }
}
#endif

import SwiftUI

struct PointOfSaleDashboardView: View {
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
            if viewModel.isInitialLoading {
                PointOfSaleLoadingView()
                    .transition(.opacity)
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
                    .transition(.push(from: .top))
            }
            POSFloatingControlView(viewModel: viewModel)
                .shadow(color: Color.black.opacity(0.08), radius: 4)
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
        .environment(\.posBackgroundAppearance, totalsViewModel.paymentState != .processingPayment ? .primary : .secondary)
        .animation(.easeInOut, value: viewModel.isInitialLoading)
        .animation(.easeInOut(duration: Constants.connectivityAnimationDuration), value: viewModel.showsConnectivityError)
        .background(Color.posPrimaryBackground)
        .navigationBarBackButtonHidden(true)
        .posModal(item: $totalsViewModel.cardPresentPaymentAlertViewModel) { alertType in
            PointOfSaleCardPresentPaymentAlert(alertType: alertType)
        }
        .posModal(isPresented: $itemListViewModel.showSimpleProductsModal) {
            SimpleProductsOnlyInformation(isPresented: $itemListViewModel.showSimpleProductsModal)
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
            await viewModel.itemListViewModel.populatePointOfSaleItems()
        }
    }

    private var contentView: some View {
        GeometryReader { geometry in
            HStack {
                if viewModel.orderStage == .building {
                    productListView
                        .accessibilitySortPriority(2)
                        .transition(.move(edge: .leading))
                }

                if !viewModel.isTotalsViewFullScreen {
                    cartView
                        .accessibilitySortPriority(1)
                        .frame(width: geometry.size.width * Constants.cartWidth)
                }

                if viewModel.orderStage == .finalizing {
                    totalsView
                        .accessibilitySortPriority(2)
                        .transition(.move(edge: .trailing))
                }
            }
            .animation(.default, value: viewModel.orderStage)
            .animation(.default, value: viewModel.isTotalsViewFullScreen)
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
    let totalsVM = TotalsViewModel(orderService: POSOrderPreviewService(),
                                   cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                   currencyFormatter: .init(currencySettings: .init()),
                                   paymentState: .acceptingCard)
    let cartVM = CartViewModel(analytics: MockAnalyticsPreview())
    let itemsListVM = ItemListViewModel(itemProvider: POSItemProviderPreview())
    let posVM = PointOfSaleDashboardViewModel(cardPresentPaymentService: CardPresentPaymentPreviewService(),
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

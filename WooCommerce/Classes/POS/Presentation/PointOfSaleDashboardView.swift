import SwiftUI
import Yosemite

struct PointOfSaleDashboardView: View {
    @EnvironmentObject private var posModel: PointOfSaleAggregateModel
    @StateObject private var itemListViewModel: PointOfSaleRootItemListViewModel = .init()

    @State private var showExitPOSModal: Bool = false
    @State private var showSupport: Bool = false

    @State private var floatingSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            if let fullscreenState = itemListViewModel.fullscreenState {
                switch fullscreenState {
                    case .initialLoading:
                        PointOfSaleLoadingView()
                            .transition(.opacity)
                            .ignoresSafeArea()
                    case .empty:
                        PointOfSaleItemListEmptyView()
                    case .error(let error):
                        PointOfSaleItemListErrorView(error: error, onRetry: {
                            Task {
                                await itemListViewModel.loadInitialItems()
                            }
                        })
                }
            } else {
                contentView
                    .accessibilitySortPriority(2)
            }

            POSFloatingControlView(showExitPOSModal: $showExitPOSModal,
                                   showSupport: $showSupport)
                .shadow(color: Color.black.opacity(0.12), radius: 4, y: 2)
                .offset(x: Constants.floatingControlHorizontalOffset, y: -Constants.floatingControlVerticalOffset)
                .trackSize(size: $floatingSize)
                .accessibilitySortPriority(1)
                .renderedIf(itemListViewModel.itemListState != .initialLoading)

            POSConnectivityView()
        }
        .environment(\.floatingControlAreaSize,
                      CGSizeMake(floatingSize.width + Constants.floatingControlHorizontalOffset,
                                 floatingSize.height + Constants.floatingControlVerticalOffset))
        .environment(\.posBackgroundAppearance, posModel.paymentState != .processingPayment ? .primary : .secondary)
        // TODO: see what this does
        .animation(.easeInOut, value: itemListViewModel.itemListState != .initialLoading)
        .background(Color.posPrimaryBackground)
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
        }
        .task {
            await itemListViewModel.loadInitialItems()
        }
    }

    private var contentView: some View {
        GeometryReader { geometry in
            HStack {
                if posModel.orderStage == .building {
                    PointOfSaleRootItemListView(viewModel: itemListViewModel)
                        .accessibilitySortPriority(2)
                        .transition(.move(edge: .leading))
                }

                if !posModel.paymentState.shownFullScreen {
                    CartView()
                        .accessibilitySortPriority(1)
                        .frame(width: geometry.size.width * Constants.cartWidth)
                        .ignoresSafeArea(edges: .bottom)
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
            posModel.cancelCardPaymentsOnboarding()
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

private extension PointOfSaleDashboardView {
    enum Constants {
        // For the moment we're just considering landscape for the POS mode
        // https://github.com/woocommerce/woocommerce-ios/issues/13251
        static let cartWidth: CGFloat = 0.35
        static let floatingControlHorizontalOffset: CGFloat = 24
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
#Preview {
    return NavigationStack {
        PointOfSaleDashboardView()
    }
}
#endif

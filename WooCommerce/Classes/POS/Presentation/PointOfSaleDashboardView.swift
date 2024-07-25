import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel
    @ObservedObject private var cartViewModel: CartViewModel

    init(viewModel: PointOfSaleDashboardViewModel,
         totalsViewModel: TotalsViewModel,
         cartViewModel: CartViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = totalsViewModel
        self.cartViewModel = cartViewModel
    }

    private var isCartShown: Bool {
        !viewModel.itemListViewModel.isEmptyOrError
    }

    @State private var floatingSize: CGSize = .zero

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            VStack {
                HStack {
                    switch viewModel.orderStage {
                    case .building:
                        GeometryReader { geometry in
                            HStack {
                                productListView
                                cartView
                                    .renderedIf(isCartShown)
                                    .frame(width: geometry.size.width * Constants.cartWidth)
                            }
                        }
                    case .finalizing:
                        GeometryReader { geometry in
                            HStack {
                                if !viewModel.isTotalsViewFullScreen {
                                    cartView
                                        .frame(width: geometry.size.width * Constants.cartWidth)
                                    Spacer()
                                }
                                totalsView
                            }
                        }
                    }
                }
                .frame(maxHeight: .infinity)
                .padding()
            }
            POSFloatingControlView(viewModel: viewModel)
                .shadow(color: Color.black.opacity(0.08), radius: 4)
                .offset(x: Constants.floatingControlHorizontalOffset, y: -Constants.floatingControlVerticalOffset)
                .trackSize(size: $floatingSize)
        }
        .environment(\.floatingControlAreaSize,
                      CGSizeMake(floatingSize.width + Constants.floatingControlHorizontalOffset,
                                 floatingSize.height + Constants.floatingControlVerticalOffset))
        .background(Color.posBackgroundGreyi3)
        .navigationBarBackButtonHidden(true)
        .sheet(isPresented: $totalsViewModel.showsCardReaderSheet, content: {
            // Might be the only way unless we make the type conform to `Identifiable`
            if let alertType = totalsViewModel.cardPresentPaymentAlertViewModel {
                PointOfSaleCardPresentPaymentAlert(alertType: alertType)
            } else {
                switch totalsViewModel.cardPresentPaymentEvent {
                case .idle,
                        .show, // handled above
                        .showOnboarding:
                    Text(totalsViewModel.cardPresentPaymentEvent.temporaryEventDescription)
                }
            }
        })
        .task {
            await viewModel.itemListViewModel.populatePointOfSaleItems()
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
        static let buttonImageAndTextSpacing: CGFloat = 12
        static let floatingControlHorizontalOffset: CGFloat = 24
        static let floatingControlVerticalOffset: CGFloat = 0
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var cartView: some View {
        CartView(viewModel: viewModel, cartViewModel: cartViewModel)
    }

    var totalsView: some View {
        TotalsView(viewModel: viewModel,
                   totalsViewModel: totalsViewModel,
                   cartViewModel: cartViewModel)
            .background(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity)
            .cornerRadius(16)
    }

    var productListView: some View {
        ItemListView(viewModel: viewModel.itemListViewModel)
    }
}

fileprivate extension CardPresentPaymentEvent {
    var temporaryEventDescription: String {
        switch self {
        case .idle:
            return "Idle"
        case .show:
            return "Event"
        case .showOnboarding(let onboardingViewModel):
            return "Onboarding: \(onboardingViewModel.state.reasonForAnalytics)" // This will only show the initial onboarding state
        }
    }
}

#if DEBUG
#Preview {
    let totalsVM = TotalsViewModel(orderService: POSOrderPreviewService(),
                                   cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                   currencyFormatter: .init(currencySettings: .init()),
                                   paymentState: .acceptingCard,
                                   isSyncingOrder: false)
    let cartVM = CartViewModel()
    let posVM = PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                              cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                              orderService: POSOrderPreviewService(),
                                              currencyFormatter: .init(currencySettings: .init()),
                                              totalsViewModel: totalsVM,
                                              cartViewModel: cartVM)

    return NavigationStack {
        PointOfSaleDashboardView(viewModel: posVM, totalsViewModel: totalsVM, cartViewModel: cartVM)
    }
}
#endif

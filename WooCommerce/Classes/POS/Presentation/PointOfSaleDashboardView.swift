import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel
    @ObservedObject private var totalsViewModel: TotalsViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
        self.totalsViewModel = viewModel.totalsViewModel
    }

    private var isCartShown: Bool {
        !viewModel.itemListViewModel.isEmptyOrError
    }

    private var floatingControlView: some View {
        HStack {
            Menu {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                        Text("Exit POS")
                    }
                }
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    HStack(spacing: Constants.buttonImageAndTextSpacing) {
                        Image(systemName: "questionmark.circle")
                        Text("Get Support")
                    }
                }
            } label: {
                HStack {
                    Text("⋯")
                        .font(.system(size: 24.0, weight: .semibold))
                }
                .frame(width: 56, height: 56)
                .background(Color.white)
                .cornerRadius(8.0)
            }
            .disabled(viewModel.isExitPOSDisabled)
            HStack {
                CardReaderConnectionStatusView(connectionViewModel: viewModel.cardReaderConnectionViewModel)
                    .padding(24)
            }
            .frame(height: 56)
            .background(Color.white)
            .cornerRadius(8.0)
        }
        .background(Color.clear)
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
            floatingControlView
                .shadow(color: Color.black.opacity(0.08), radius: 4)
                .offset(x: Constants.floatingControlOffset, y: -Constants.floatingControlOffset)
                .trackSize(size: $floatingSize)
        }
        .environment(\.floatingControlAreaSize,
                      CGSizeMake(floatingSize.width + Constants.floatingControlOffset,
                                 floatingSize.height + Constants.floatingControlOffset))
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
                    Text(viewModel.totalsViewModel.cardPresentPaymentEvent.temporaryEventDescription)
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
        static let floatingControlOffset: CGFloat = 24
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var collapsedCartView: some View {
        CollapsedCartView()
    }

    var cartView: some View {
        CartView(viewModel: viewModel,
                 cartViewModel: viewModel.cartViewModel)
    }

    var totalsView: some View {
        TotalsView(viewModel: viewModel,
                   totalsViewModel: viewModel.totalsViewModel)
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
    NavigationStack {
        PointOfSaleDashboardView(
            viewModel: PointOfSaleDashboardViewModel(itemProvider: POSItemProviderPreview(),
                                                     cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                     orderService: POSOrderPreviewService(),
                                                     currencyFormatter: .init(currencySettings: .init())))
    }
}
#endif

import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            HStack {
                switch viewModel.orderStage {
                case .building:
                    productGridView
                    Spacer()
                    if viewModel.isCartCollapsed {
                        collapsedCartView
                    } else {
                        cartView
                    }
                case .finalizing:
                    cartView
                    Spacer()
                    totalsView
                }
            }
            .padding()
        }
        .task {
            await viewModel.populatePointOfSaleItems()
        }
        .background(Color.posBackgroundGreyi3)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                POSToolbarView(readerConnectionViewModel: viewModel.cardReaderConnectionViewModel)
            }
        }
        .toolbarBackground(Color.toolbarBackground, for: .bottomBar)
        .toolbarBackground(.visible, for: .bottomBar)
        .sheet(isPresented: $viewModel.showsCardReaderSheet, content: {
            // Might be the only way unless we make the type conform to `Identifiable`
            if let alertType = viewModel.cardPresentPaymentAlertViewModel {
                PointOfSaleCardPresentPaymentAlert(alertType: alertType)
            } else {
                switch viewModel.cardPresentPaymentEvent {
                case let .showReaderList(readerIDs, selectionHandler):
                    // TODO: make this an instance of `showAlert` so we can handle it above too.
                    FoundCardReaderListView(readerIDs: readerIDs, connect: { readerID in
                        selectionHandler(readerID)
                    }, cancelSearch: {
                        selectionHandler(nil)
                    })
                case .idle,
                        .show, // handled above
                        .showOnboarding:
                    Text(viewModel.cardPresentPaymentEvent.temporaryEventDescription)
                }
            }
        })
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var collapsedCartView: some View {
        CollapsedCartView()
    }

    var cartView: some View {
        CartView(viewModel: viewModel)
            .frame(maxWidth: .infinity)
    }

    var totalsView: some View {
        TotalsView(viewModel: viewModel)
            .background(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity)
            .cornerRadius(16)
    }

    var productGridView: some View {
        ItemListView(viewModel: viewModel)
            .frame(maxWidth: .infinity)
    }
}

fileprivate extension CardPresentPaymentEvent {
    var temporaryEventDescription: String {
        switch self {
        case .idle:
            return "Idle"
        case .show:
            return "Event"
        case .showReaderList(let readerIDs, _):
            return "Reader List: \(readerIDs.joined())"
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
                                                     orderService: POSOrderPreviewService()))
    }
}
#endif

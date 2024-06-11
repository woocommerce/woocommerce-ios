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
                    cartView
                case .finalizing:
                    cartView
                    Spacer()
                    totalsView
                }
            }
            .padding()
        }
        .background(Color.primaryBackground)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                POSToolbarView(readerConnectionViewModel: viewModel.cardReaderConnectionViewModel)
            }
        }
        .sheet(isPresented: $viewModel.showsCardReaderSheet, content: {
            switch viewModel.cardPresentPaymentEvent {
            case .showAlert(let alertViewModel):
                CardPresentPaymentAlert(alertViewModel: alertViewModel)
            case let .showReaderList(readerIDs, selectionHandler):
                FoundCardReaderListView(readerIDs: readerIDs, connect: { readerID in
                    selectionHandler(readerID)
                }, cancelSearch: {
                    selectionHandler(nil)
                })
            case .idle,
                    .showOnboarding:
                Text(viewModel.cardPresentPaymentEvent.temporaryEventDescription)
            }
        })
        .sheet(isPresented: $viewModel.showsFilterSheet, content: {
            FilterView(viewModel: viewModel)
        })
    }
}

/// Helpers to generate all Dashboard subviews
private extension PointOfSaleDashboardView {
    var cartView: some View {
        CartView(viewModel: viewModel)
            .background(Color.secondaryBackground)
            .frame(maxWidth: .infinity)
    }

    var totalsView: some View {
        TotalsView(viewModel: viewModel)
            .background(Color(UIColor.systemBackground))
            .frame(maxWidth: .infinity)
    }

    var productGridView: some View {
        ItemGridView(viewModel: viewModel)
            .background(Color.secondaryBackground)
            .frame(maxWidth: .infinity)
    }
}

fileprivate extension CardPresentPaymentEvent {
    var temporaryEventDescription: String {
        switch self {
        case .idle:
            return "Idle"
        case .showAlert(let alertViewModel):
            return "Alert: \(alertViewModel.topTitle)"
        case .showReaderList(let readerIDs, _):
            return "Reader List: \(readerIDs.joined())"
        case .showOnboarding(let onboardingViewModel):
            return "Onboarding: \(onboardingViewModel.state.reasonForAnalytics)" // This will only show the initial onboarding state
        }
    }
}

#if DEBUG
#Preview {
    PointOfSaleDashboardView(
        viewModel: PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                 cardPresentPaymentService: CardPresentPaymentPreviewService()))
}
#endif

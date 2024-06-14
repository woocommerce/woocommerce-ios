import SwiftUI
import protocol Yosemite.PointOfSaleOrderServiceProtocol
import class Yosemite.PointOfSaleOrderService
import enum Networking.Credentials

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
                        VStack {
                            totalsView
                            // TODO: replace temporary inline message UI based on design
                            if let inlinePaymentMessage = viewModel.cardPresentPaymentInlineMessage {
                                switch inlinePaymentMessage {
                                    case .preparingForPayment:
                                        Text("Preparing for payment...")
                                    case .tapSwipeOrInsertCard:
                                        Text("tapSwipeOrInsertCard...")
                                    case .processing:
                                        Text("processing...")
                                    case .displayReaderMessage(let message):
                                        Text("Reader message: \(message)")
                                    case .success:
                                        Text("Payment successful!")
                                    case .error:
                                        Text("Payment error")
                                }
                            }
                        }
                        // TODO: remove this after replacing temporary inline message UI based on design
                        .background(Color.orange)
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
        .toolbarBackground(Color.toolbarBackground, for: .bottomBar)
        .toolbarBackground(.visible, for: .bottomBar)
        .sheet(isPresented: $viewModel.showsCardReaderSheet, content: {
            // Might be the only way unless we make the type conform to `Identifiable`
            if let alertType = viewModel.cardPresentPaymentAlertViewModel {
                CardPresentPaymentAlert(alertType: alertType)
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
                        .showAlert, // handled abo ve
                        .showOnboarding,
                        .showPaymentMessage:
                    Text(viewModel.cardPresentPaymentEvent.temporaryEventDescription)
                }
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
        case .showAlert(let alertDetails):
            return "Alert"
        case .showReaderList(let readerIDs, _):
            return "Reader List: \(readerIDs.joined())"
        case .showOnboarding(let onboardingViewModel):
            return "Onboarding: \(onboardingViewModel.state.reasonForAnalytics)" // This will only show the initial onboarding state
        case .showPaymentMessage:
            return "Payment message"
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PointOfSaleDashboardView(
            viewModel: PointOfSaleDashboardViewModel(items: POSItemProviderPreview().providePointOfSaleItems(),
                                                     cardPresentPaymentService: CardPresentPaymentPreviewService(),
                                                     orderService: PointOfSaleOrderService(siteID: Int64.min, credentials: Credentials(authToken: "token"))))
    }
}
#endif

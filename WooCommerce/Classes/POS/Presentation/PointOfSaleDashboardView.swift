import class Yosemite.POSProductProvider
import SwiftUI

struct PointOfSaleDashboardView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject private var viewModel: PointOfSaleDashboardViewModel

    init(viewModel: PointOfSaleDashboardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Text("WooCommerce Point Of Sale")
                .foregroundColor(Color.white)
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
            ToolbarItem(placement: .topBarLeading, content: {
                Button("Exit POS") {
                    presentationMode.wrappedValue.dismiss()
                }
            })
            ToolbarItem(placement: .principal, content: {
                CardReaderConnectionStatusView(connectionViewModel: viewModel.cardReaderConnectionViewModel)
            })
            ToolbarItem(placement: .primaryAction, content: {
                Button("History") {
                    debugPrint("Not implemented")
                }
            })
        }
        .sheet(isPresented: $viewModel.showsCardReaderSheet, content: {
            switch viewModel.cardPresentPaymentEvent {
            case .showAlert(let alertViewModel):
                CardPresentPaymentAlert(alertViewModel: alertViewModel)
            case let .showWCSettingsWebView(adminURL, completion):
                WCSettingsWebView(adminUrl: adminURL, completion: completion)
            case .idle,
                    .showReaderList,
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
            .background(Color.secondaryBackground)
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
        case .showWCSettingsWebView(let adminURL, _):
            return "WC Settings: \(adminURL.absoluteString)"
        }
    }
}

#if DEBUG
#Preview {
    // TODO: https://github.com/woocommerce/woocommerce-ios/issues/12917
    // The Yosemite imports are only needed for previews
    PointOfSaleDashboardView(viewModel: PointOfSaleDashboardViewModel(items: POSProductProvider.provideProductsForPreview(),
                                                                      currencySettings: .init(),
                                                                      cardPresentPaymentService: CardPresentPaymentService(siteID: 0)))
}
#endif

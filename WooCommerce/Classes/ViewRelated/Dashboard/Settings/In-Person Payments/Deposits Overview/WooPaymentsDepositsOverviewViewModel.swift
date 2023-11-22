import Foundation

final class WooPaymentsDepositsOverviewViewModel: ObservableObject {
    @Published var currencyViewModels: [WooPaymentsDepositsCurrencyOverviewViewModel]

    let analytics: Analytics

    init(currencyViewModels: [WooPaymentsDepositsCurrencyOverviewViewModel],
         analytics: Analytics = ServiceLocator.analytics) {
        self.currencyViewModels = currencyViewModels
        self.analytics = analytics
    }

    func currencySelected(currencyViewModel: WooPaymentsDepositsCurrencyOverviewViewModel) {
        analytics.track(event: .DepositSummary.depositSummaryCurrencySelected(currency: currencyViewModel.currency))
    }
}

import Foundation
import protocol WooFoundation.Analytics

final class WooPaymentsDepositsOverviewViewModel: ObservableObject {
    @Published var currencyViewModels: [WooPaymentsDepositsCurrencyOverviewViewModel]

    let analytics: Analytics

    init(currencyViewModels: [WooPaymentsDepositsCurrencyOverviewViewModel],
         analytics: Analytics = ServiceLocator.analytics) {
        self.currencyViewModels = currencyViewModels
        self.analytics = analytics
    }

    func onAppear() {
        analytics.track(event: .DepositSummary.depositSummaryShown(numberOfCurrencies: currencyViewModels.count))
    }

    func currencySelected(currencyViewModel: WooPaymentsDepositsCurrencyOverviewViewModel) {
        analytics.track(event: .DepositSummary.depositSummaryCurrencySelected(currency: currencyViewModel.currency))
    }
}

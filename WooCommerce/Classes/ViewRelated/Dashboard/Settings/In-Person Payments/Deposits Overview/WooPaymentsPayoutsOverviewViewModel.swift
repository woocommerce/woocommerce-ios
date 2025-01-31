import Foundation
import protocol WooFoundation.Analytics

final class WooPaymentsPayoutsOverviewViewModel: ObservableObject {
    @Published var currencyViewModels: [WooPaymentsPayoutsCurrencyOverviewViewModel]

    let analytics: Analytics

    init(currencyViewModels: [WooPaymentsPayoutsCurrencyOverviewViewModel],
         analytics: Analytics = ServiceLocator.analytics) {
        self.currencyViewModels = currencyViewModels
        self.analytics = analytics
    }

    func onAppear() {
        analytics.track(event: .PayoutSummary.payoutSummaryShown(numberOfCurrencies: currencyViewModels.count))
    }

    func currencySelected(currencyViewModel: WooPaymentsPayoutsCurrencyOverviewViewModel) {
        analytics.track(event: .PayoutSummary.payoutSummaryCurrencySelected(currency: currencyViewModel.currency))
    }
}

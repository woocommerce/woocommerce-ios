import SwiftUI
import Yosemite

@available(iOS 16.0, *)
struct WooPaymentsDepositsOverviewView: View {
    let viewModels: [WooPaymentsDepositsCurrencyOverviewViewModel]

    @State var isExpanded: Bool = false

    var tabs: [TopTabItem] {
        viewModels.map { tabViewModel in
            TopTabItem(name: tabViewModel.tabTitle,
                       view: AnyView(WooPaymentsDepositsCurrencyOverviewView(viewModel: tabViewModel,
                                                                             isExpanded: $isExpanded)),
                       onSelected: {
                ServiceLocator.analytics.track(
                    event: .DepositSummary.depositSummaryCurrencySelected(currency: tabViewModel.currency))
            })
        }
    }

    var body: some View {
        VStack {
            TopTabView(tabs: tabs,
                       showTabs: $isExpanded)
        }
    }
}

@available(iOS 16.0, *)
struct WooPaymentsDepositsOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let overviewData = WooPaymentsDepositsOverviewByCurrency(
            currency: .GBP,
            automaticDeposits: true,
            depositInterval: .daily,
            pendingBalanceAmount: 1000.0,
            pendingDepositsCount: 5,
            pendingDepositDays: 7,
            nextDeposit: WooPaymentsDepositsOverviewByCurrency.NextDeposit(
                amount: 250.0,
                date: Date(),
                status: .pending
            ),
            lastDeposit: WooPaymentsDepositsOverviewByCurrency.LastDeposit(
                amount: 500.0,
                date: Date()
            ),
            availableBalance: 1500.0
        )

        let viewModel1 = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overviewData)

        let overviewData2 = WooPaymentsDepositsOverviewByCurrency(
            currency: .EUR,
            automaticDeposits: true,
            depositInterval: .daily,
            pendingBalanceAmount: 200.0,
            pendingDepositsCount: 5,
            pendingDepositDays: 7,
            nextDeposit: WooPaymentsDepositsOverviewByCurrency.NextDeposit(
                amount: 190.0,
                date: Date(),
                status: .pending
            ),
            lastDeposit: WooPaymentsDepositsOverviewByCurrency.LastDeposit(
                amount: 600.0,
                date: Date()
            ),
            availableBalance: 1900.0
        )

        let viewModel2 = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overviewData2)

        WooPaymentsDepositsOverviewView(viewModels: [viewModel1, viewModel2])
    }
}

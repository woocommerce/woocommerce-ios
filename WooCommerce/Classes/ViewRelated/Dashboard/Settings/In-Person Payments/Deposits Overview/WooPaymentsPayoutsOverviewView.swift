import SwiftUI
import Yosemite

struct WooPaymentsPayoutsOverviewView: View {
    @ObservedObject var viewModel: WooPaymentsPayoutsOverviewViewModel

    @State var isExpanded: Bool = false

    var tabs: [TopTabItem<WooPaymentsPayoutsCurrencyOverviewView>] {
        viewModel.currencyViewModels.map { currencyViewModel in
            TopTabItem(name: currencyViewModel.tabTitle,
                       content: {
                WooPaymentsPayoutsCurrencyOverviewView(viewModel: currencyViewModel,
                                                        isExpanded: $isExpanded)
            }, onSelected: {
                viewModel.currencySelected(currencyViewModel: currencyViewModel)
            })
        }
    }

    var body: some View {
        VStack {
            TopTabView(tabs: tabs,
                       showTabs: $isExpanded)
        }
        Divider()
        .onAppear(perform: viewModel.onAppear)
    }
}

struct WooPaymentsPayoutsOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let overviewData = WooPaymentsPayoutsOverviewByCurrency(
            currency: .GBP,
            automaticPayouts: true,
            payoutInterval: .daily,
            pendingBalanceAmount: 1000.0,
            pendingPayoutDays: 7,
            lastPayout: WooPaymentsPayoutsOverviewByCurrency.LastPayout(
                amount: 500.0,
                date: Date(),
                status: .inTransit
            ),
            availableBalance: 1500.0
        )

        let viewModel1 = WooPaymentsPayoutsCurrencyOverviewViewModel(overview: overviewData)

        let overviewData2 = WooPaymentsPayoutsOverviewByCurrency(
            currency: .EUR,
            automaticPayouts: true,
            payoutInterval: .daily,
            pendingBalanceAmount: 200.0,
            pendingPayoutDays: 7,
            lastPayout: WooPaymentsPayoutsOverviewByCurrency.LastPayout(
                amount: 600.0,
                date: Date(),
                status: .canceled
            ),
            availableBalance: 1900.0
        )

        let viewModel2 = WooPaymentsPayoutsCurrencyOverviewViewModel(overview: overviewData2)

        WooPaymentsPayoutsOverviewView(viewModel: .init(currencyViewModels: [viewModel1, viewModel2]))
    }
}

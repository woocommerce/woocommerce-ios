import SwiftUI
import Yosemite

@available(iOS 16.0, *)
struct WooPaymentsDepositsOverviewView: View {
    @ObservedObject var viewModel: WooPaymentsDepositsOverviewViewModel

    @State var isExpanded: Bool = false

    var tabs: [TopTabItem<WooPaymentsDepositsCurrencyOverviewView>] {
        viewModel.currencyViewModels.map { currencyViewModel in
            TopTabItem(name: currencyViewModel.tabTitle,
                       content: {
                WooPaymentsDepositsCurrencyOverviewView(viewModel: currencyViewModel,
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

@available(iOS 16.0, *)
struct WooPaymentsDepositsOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let overviewData = WooPaymentsDepositsOverviewByCurrency(
            currency: .GBP,
            automaticDeposits: true,
            depositInterval: .daily,
            pendingBalanceAmount: 1000.0,
            pendingDepositDays: 7,
            lastDeposit: WooPaymentsDepositsOverviewByCurrency.LastDeposit(
                amount: 500.0,
                date: Date(),
                status: .inTransit
            ),
            availableBalance: 1500.0
        )

        let viewModel1 = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overviewData)

        let overviewData2 = WooPaymentsDepositsOverviewByCurrency(
            currency: .EUR,
            automaticDeposits: true,
            depositInterval: .daily,
            pendingBalanceAmount: 200.0,
            pendingDepositDays: 7,
            lastDeposit: WooPaymentsDepositsOverviewByCurrency.LastDeposit(
                amount: 600.0,
                date: Date(),
                status: .canceled
            ),
            availableBalance: 1900.0
        )

        let viewModel2 = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overviewData2)

        WooPaymentsDepositsOverviewView(viewModel: .init(currencyViewModels: [viewModel1, viewModel2]))
    }
}

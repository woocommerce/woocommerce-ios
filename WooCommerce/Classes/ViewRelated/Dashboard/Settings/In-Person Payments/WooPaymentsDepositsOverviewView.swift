import SwiftUI
import Yosemite

@available(iOS 16.0, *)
struct WooPaymentsDepositsOverviewView: View {
    let viewModels: [WooPaymentsDepositsCurrencyOverviewViewModel]

    var tabs: [TopTabItem] {
        viewModels.map { tabViewModel in
            TopTabItem(name: tabViewModel.overview.currency.rawValue,
                       view: AnyView(WooPaymentsDepositsCurrencyOverviewView(viewModel: tabViewModel)))
        }
    }

    var body: some View {
        VStack {
            TopTabView(tabs: tabs)

            Button {
                // TODO: Open a webview here: https://woocommerce.com/document/woopayments/deposits/deposit-schedule/
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                    Text(Localization.learnMoreButtonText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.footnote)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding()

            Spacer()
        }
    }
}

@available(iOS 16.0, *)
private extension WooPaymentsDepositsOverviewView {
    enum Localization {
        static let learnMoreButtonText = NSLocalizedString(
            "Learn more about when you'll receive your funds",
            comment: "Button text to view more about payment schedules on the WooPayments Deposits View.")
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

import SwiftUI
import Yosemite

@available(iOS 16.0, *)
struct WooPaymentsDepositsCurrencyOverviewView: View {
    @ObservedObject var viewModel: WooPaymentsDepositsCurrencyOverviewViewModel

    init(viewModel: WooPaymentsDepositsCurrencyOverviewViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack {
            Grid(alignment: .leading) {
                Text("\(viewModel.overview.currency.name) (\(viewModel.overview.currency.rawValue))")
                    .font(.title2)
                    .fontWeight(.bold)

                GridRow {
                    AccountSummaryItem(title: "Available funds",
                                      amount: viewModel.availableBalance,
                                      footer: "")
                    AccountSummaryItem(title: "Pending funds",
                                      amount: viewModel.pendingBalance,
                                       footer: "\(viewModel.overview.pendingDepositsCount) deposits")
                }

                HStack(alignment: .top) {
                    Image(systemName: "calendar")
                    Text("Funds become available after pending for 7 days.")
                        .font(.footnote)
                }
                .padding(.vertical, 8)

                GridRow {
                    AccountSummaryItem(title: "Next deposit",
                                      amount: viewModel.nextDepositAmount,
                                      footer: "Est. \(viewModel.nextDepositDate)")
                    AccountSummaryItem(title: "Last deposit",
                                      amount: viewModel.lastDepositAmount,
                                      footer: viewModel.lastDepositDate)

                }

                HStack(alignment: .top) {
                    Image(systemName: "building.columns")
                    Text("Available funds are deposited \(viewModel.overview.automaticDeposits ? "automatically" : "manually"), \(viewModel.overview.depositInterval.frequencyDescriptionEvery).")
                        .font(.footnote)
                }
                .padding(.vertical, 8)
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
    }
}

struct AccountSummaryItem: View {
    let title: String
    let amount: String
    let footer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(amount)
                .font(.title2)
                .fontWeight(.bold)

            Text(footer)
                .font(.footnote)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .border(Color(uiColor: .separator), width: 1)
    }
}

@available(iOS 16.0, *)
struct WooPaymentsDepositsCurrencyOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let overviewData = WooPaymentsDepositsOverviewByCurrency(
            currency: .GBP,
            automaticDeposits: true,
            depositInterval: .daily,
            pendingBalanceAmount: 1000.0,
            pendingDepositsCount: 5,
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

        let viewModel = WooPaymentsDepositsCurrencyOverviewViewModel(overview: overviewData)

        return WooPaymentsDepositsCurrencyOverviewView(viewModel: viewModel)
            .previewLayout(.sizeThatFits)
//            .frame(width: 400, height: 400)
    }
}

private extension WooPaymentsDepositInterval {
    var frequencyDescriptionEvery: String {
        switch self {
        case .daily:
            return NSLocalizedString(
                "depositsOverview.interval.every.day",
                comment: "every day (lower case), shown in a sentence like 'Deposit schedule: automatic, every day'")
        case .weekly:
            return NSLocalizedString(
                "depositsOverview.interval.every.week",
                comment: "every week (lower case), shown in a sentence like 'Deposit schedule: automatic, every week'")
        case .monthly:
            return NSLocalizedString(
                "depositsOverview.interval.every.month",
                comment: "every month (lower case), shown in a sentence like 'Deposit schedule: automatic, every month'")
        case .manual:
            return NSLocalizedString(
                "depositsOverview.interval.manual",
                comment: "on request (lower case), shown in a sentence like 'Deposit schedule: manual, on request'")
        }
    }
}

import SwiftUI
import Yosemite

@available(iOS 16.0, *)
struct WooPaymentsDepositsOverviewView: View {
    @ObservedObject var viewModel: WooPaymentsDepositsOverviewViewModel

    init(viewModel: WooPaymentsDepositsOverviewViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("\(viewModel.overview.currency.name) (\(viewModel.overview.currency.rawValue)) balance")
                .font(.title)
                .fontWeight(.bold)

            HStack {
                Image(systemName: "calendar")
                    .foregroundColor(.blue)

                Text("Deposit schedule: \(viewModel.overview.automaticDeposits ? "Automatic" : "Manual"), \(viewModel.overview.depositInterval.frequencyDescriptionEvery)")
                    .font(.footnote)
            }

            Grid {
                GridRow {
                    AccountSummaryBox(title: "Pending Balance", amount: viewModel.pendingBalance, footer: "\(viewModel.overview.pendingDepositsCount) deposits")
                    AccountSummaryBox(title: "Next Deposit", amount: viewModel.nextDepositAmount, footer: "Est. \(viewModel.nextDepositDate)")
                }
                GridRow {
                    AccountSummaryBox(title: "Last Deposit", amount: viewModel.lastDepositAmount, footer: viewModel.lastDepositDate)
                    AccountSummaryBox(title: "Available Balance", amount: viewModel.availableBalance, footer: "")
                }
            }
        }
        .padding()
    }
}

struct AccountSummaryBox: View {
    let title: String
    let amount: String
    let footer: String

    var body: some View {
        VStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(amount)
                .font(.title)
                .fontWeight(.bold)

            Text(footer)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 3)
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

        let viewModel = WooPaymentsDepositsOverviewViewModel(overview: overviewData)

        return WooPaymentsDepositsOverviewView(viewModel: viewModel)
            .previewLayout(.sizeThatFits)
            .frame(width: 400, height: 400)
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

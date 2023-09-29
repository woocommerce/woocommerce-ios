import Foundation
import Yosemite

class WooPaymentsDepositsCurrencyOverviewViewModel: ObservableObject {
    let overview: WooPaymentsDepositsOverviewByCurrency

    init(overview: WooPaymentsDepositsOverviewByCurrency) {
        self.overview = overview
        setupProperties()
    }

    private func setupProperties() {
        pendingBalance = formatAmount(overview.pendingBalanceAmount)
        nextDepositAmount = formatAmount(overview.nextDeposit?.amount ?? NSDecimalNumber(value: 0))
        lastDepositAmount = formatAmount(overview.lastDeposit?.amount ?? NSDecimalNumber(value: 0))
        nextDepositDate = nextDepositDateText()
        lastDepositDate = formatDate(overview.lastDeposit?.date) ?? "N/A"
        availableBalance = formatAmount(overview.availableBalance)
        depositScheduleHint = depositScheduleHintText()
        balanceTypeHint = balanceTypeHintText()
    }

    @Published var pendingBalance: String = ""
    @Published var nextDepositAmount: String = ""
    @Published var lastDepositAmount: String = ""
    @Published var nextDepositDate: String = ""
    @Published var lastDepositDate: String = ""
    @Published var availableBalance: String = ""
    @Published var depositScheduleHint: String = ""
    @Published var balanceTypeHint: String = ""

    private func formatAmount(_ amount: NSDecimalNumber) -> String {
        return numberFormatter.string(from: amount) ?? ""
    }

    private func nextDepositDateText() -> String {
        guard let dateString = formatDate(overview.nextDeposit?.date) else {
            return "N/A"
        }
        return "Est. \(dateString)"
    }

    private func depositScheduleHintText() -> String {
        "Available funds are deposited \(overview.automaticDeposits ? "automatically" : "manually"), \(overview.depositInterval.frequencyDescriptionEvery)."
    }

    private func balanceTypeHintText() -> String {
        //TODO: use the number from the API, not just 7
        "Funds become available after pending for 7 days."
    }

    private func formatDate(_ date: Date?) -> String? {
        guard let date = date else {
            return nil
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }

    private lazy var numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = overview.currency.rawValue
        return formatter
    }()
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

import Foundation
import Yosemite

class WooPaymentsDepositsOverviewViewModel: ObservableObject {
    let overview: WooPaymentsDepositsOverviewByCurrency

    init(overview: WooPaymentsDepositsOverviewByCurrency) {
        self.overview = overview
        setupProperties()
    }

    private func setupProperties() {
        pendingBalance = formatAmount(overview.pendingBalanceAmount)
        nextDepositAmount = formatAmount(overview.nextDeposit?.amount ?? NSDecimalNumber(value: 0))
        lastDepositAmount = formatAmount(overview.lastDeposit?.amount ?? NSDecimalNumber(value: 0))
        nextDepositDate = formatDate(overview.nextDeposit?.date)
        lastDepositDate = formatDate(overview.lastDeposit?.date)
        availableBalance = formatAmount(overview.availableBalance)
    }

    @Published var pendingBalance: String = ""
    @Published var nextDepositAmount: String = ""
    @Published var lastDepositAmount: String = ""
    @Published var nextDepositDate: String = ""
    @Published var lastDepositDate: String = ""
    @Published var availableBalance: String = ""

    private func formatAmount(_ amount: NSDecimalNumber) -> String {
        return numberFormatter.string(from: amount) ?? ""
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else {
            return "N/A"
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = overview.currency.rawValue
        return formatter
    }
}

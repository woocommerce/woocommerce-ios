import Foundation
import WooFoundation
import Networking
import Codegen

public struct WooPaymentsDepositsOverviewByCurrency: GeneratedCopiable, GeneratedFakeable {
    public let currency: CurrencyCode
    public let automaticDeposits: Bool
    public let depositInterval: WooPaymentsDepositInterval
    public let pendingBalanceAmount: NSDecimalNumber
    public let pendingDepositDays: Int
    public let lastDeposit: LastDeposit?
    public let availableBalance: NSDecimalNumber

    public struct LastDeposit {
        public let amount: NSDecimalNumber
        public let date: Date
        public let status: WooPaymentsDepositStatus

        public init(amount: NSDecimalNumber, date: Date, status: WooPaymentsDepositStatus) {
            self.amount = amount
            self.date = date
            self.status = status
        }
    }

    public init(currency: CurrencyCode,
                automaticDeposits: Bool,
                depositInterval: WooPaymentsDepositInterval,
                pendingBalanceAmount: NSDecimalNumber,
                pendingDepositDays: Int,
                lastDeposit: LastDeposit?,
                availableBalance: NSDecimalNumber) {
        self.currency = currency
        self.automaticDeposits = automaticDeposits
        self.depositInterval = depositInterval
        self.pendingBalanceAmount = pendingBalanceAmount
        self.pendingDepositDays = pendingDepositDays
        self.lastDeposit = lastDeposit
        self.availableBalance = availableBalance
    }
}

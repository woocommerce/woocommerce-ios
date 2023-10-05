import Foundation
import WooFoundation
import Networking

public struct WooPaymentsDepositsOverviewByCurrency {
    public let currency: CurrencyCode
    public let automaticDeposits: Bool
    public let depositInterval: WooPaymentsDepositInterval
    public let pendingBalanceAmount: NSDecimalNumber
    public let pendingDepositsCount: Int
    public let pendingDepositDays: Int
    public let nextDeposit: NextDeposit?
    public let lastDeposit: LastDeposit?
    public let availableBalance: NSDecimalNumber

    public struct NextDeposit {
        public let amount: NSDecimalNumber
        public let date: Date
        public let status: WooPaymentsDepositStatus

        public init(amount: NSDecimalNumber, date: Date, status: WooPaymentsDepositStatus) {
            self.amount = amount
            self.date = date
            self.status = status
        }
    }

    public struct LastDeposit {
        public let amount: NSDecimalNumber
        public let date: Date

        public init(amount: NSDecimalNumber, date: Date) {
            self.amount = amount
            self.date = date
        }
    }

    public init(currency: CurrencyCode,
                automaticDeposits: Bool,
                depositInterval: WooPaymentsDepositInterval,
                pendingBalanceAmount: NSDecimalNumber,
                pendingDepositsCount: Int,
                pendingDepositDays: Int,
                nextDeposit: NextDeposit?,
                lastDeposit: LastDeposit?,
                availableBalance: NSDecimalNumber) {
        self.currency = currency
        self.automaticDeposits = automaticDeposits
        self.depositInterval = depositInterval
        self.pendingBalanceAmount = pendingBalanceAmount
        self.pendingDepositsCount = pendingDepositsCount
        self.pendingDepositDays = pendingDepositDays
        self.nextDeposit = nextDeposit
        self.lastDeposit = lastDeposit
        self.availableBalance = availableBalance
    }
}

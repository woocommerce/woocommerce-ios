import Foundation
import WooFoundation
import Networking

public struct WooPaymentsPayoutsOverviewByCurrency {
    public let currency: CurrencyCode
    public let automaticPayouts: Bool
    public let payoutInterval: WooPaymentsPayoutInterval
    public let pendingBalanceAmount: NSDecimalNumber
    public let pendingPayoutsCount: Int
    public let pendingPayoutDays: Int
    public let nextPayout: NextPayout?
    public let lastPayout: LastPayout?
    public let availableBalance: NSDecimalNumber

    public struct NextPayout {
        public let amount: NSDecimalNumber
        public let date: Date
        public let status: WooPaymentsPayoutStatus

        public init(amount: NSDecimalNumber, date: Date, status: WooPaymentsPayoutStatus) {
            self.amount = amount
            self.date = date
            self.status = status
        }
    }

    public struct LastPayout {
        public let amount: NSDecimalNumber
        public let date: Date

        public init(amount: NSDecimalNumber, date: Date) {
            self.amount = amount
            self.date = date
        }
    }

    public init(currency: CurrencyCode,
                automaticPayouts: Bool,
                payoutInterval: WooPaymentsPayoutInterval,
                pendingBalanceAmount: NSDecimalNumber,
                pendingPayoutsCount: Int,
                pendingPayoutDays: Int,
                nextPayout: NextPayout?,
                lastPayout: LastPayout?,
                availableBalance: NSDecimalNumber) {
        self.currency = currency
        self.automaticPayouts = automaticPayouts
        self.payoutInterval = payoutInterval
        self.pendingBalanceAmount = pendingBalanceAmount
        self.pendingPayoutsCount = pendingPayoutsCount
        self.pendingPayoutDays = pendingPayoutDays
        self.nextPayout = nextPayout
        self.lastPayout = lastPayout
        self.availableBalance = availableBalance
    }
}

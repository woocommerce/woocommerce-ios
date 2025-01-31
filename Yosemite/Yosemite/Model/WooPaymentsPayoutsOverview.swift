import Foundation
import WooFoundation
import Networking
import Codegen

public struct WooPaymentsPayoutsOverviewByCurrency: GeneratedCopiable, GeneratedFakeable {
    public let currency: CurrencyCode
    public let automaticPayouts: Bool
    public let payoutInterval: WooPaymentsPayoutInterval
    public let pendingBalanceAmount: NSDecimalNumber
    public let pendingPayoutDays: Int
    public let lastPayout: LastPayout?
    public let availableBalance: NSDecimalNumber

    public struct LastPayout {
        public let amount: NSDecimalNumber
        public let date: Date
        public let status: WooPaymentsPayoutStatus

        public init(amount: NSDecimalNumber, date: Date, status: WooPaymentsPayoutStatus) {
            self.amount = amount
            self.date = date
            self.status = status
        }
    }

    public init(currency: CurrencyCode,
                automaticPayouts: Bool,
                payoutInterval: WooPaymentsPayoutInterval,
                pendingBalanceAmount: NSDecimalNumber,
                pendingPayoutDays: Int,
                lastPayout: LastPayout?,
                availableBalance: NSDecimalNumber) {
        self.currency = currency
        self.automaticPayouts = false
        self.payoutInterval = payoutInterval
        self.pendingBalanceAmount = pendingBalanceAmount
        self.pendingPayoutDays = pendingPayoutDays
        self.lastPayout = lastPayout
        self.availableBalance = availableBalance
    }
}

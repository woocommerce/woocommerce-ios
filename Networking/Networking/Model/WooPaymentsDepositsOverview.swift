import Foundation
import Codegen

public struct WooPaymentsDepositsOverview: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let deposit: WooPaymentsCurrencyDeposits
    let balance: WooPaymentsCurrencyBalances
    let account: WooPaymentsAccountDepositSummary
}

public struct WooPaymentsCurrencyDeposits: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let lastPaid: [WooPaymentsDeposit]
    let nextScheduled: [WooPaymentsDeposit]
    let lastManualDeposits: [WooPaymentsDeposit]
}

public struct WooPaymentsDeposit: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let id: String
    let date: Date
    let type: String
    let amount: Int
    let status: String
    let bankAccount: String
    let currency: String
    let automatic: Bool
    let fee: Int
    let feePercentage: Int
    let created: Int
}

public struct WooPaymentsCurrencyBalances: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let pending: [WooPaymentsBalance]
    let available: [WooPaymentsBalance]
    let instant: [WooPaymentsBalance]
}

public struct WooPaymentsBalance: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let amount: Int
    let currency: String
    let sourceTypes: WooPaymentsSourceTypes
    let depositsCount: Int?

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case sourceTypes = "source_types"
        case depositsCount = "deposits_count"
    }
}

public struct WooPaymentsSourceTypes: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let card: Int
}

public struct WooPaymentsInstantBalance: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    // Define properties for the 'instant_balance' object if needed.
}

public struct WooPaymentsAccountDepositSummary: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let depositsEnabled: Bool
    let depositsBlocked: Bool
    let depositsSchedule: WooPaymentsDepositsSchedule
    let defaultCurrency: String

    enum CodingKeys: String, CodingKey {
        case depositsEnabled = "deposits_enabled"
        case depositsBlocked = "deposits_blocked"
        case depositsSchedule = "deposits_schedule"
        case defaultCurrency = "default_currency"
    }
}

public struct WooPaymentsDepositsSchedule: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let delayDays: Int
    let interval: WooPaymentsDepositInterval
}

/// originally from https://stripe.com/docs/api/accounts/object#account_object-settings-payouts-schedule-interval
public enum WooPaymentsDepositInterval: String, Codable {
    case daily
    case weekly
    case monthly
    case manual
}

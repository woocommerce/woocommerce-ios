import Foundation
import Codegen

public struct WooPaymentsDepositsOverview: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let lastDeposit: WooPaymentsDeposit?
    let nextDeposit: WooPaymentsDeposit?
    let availableBalance: WooPaymentsBalance?
    let pendingBalance: WooPaymentsBalance?
    let instantBalance: WooPaymentsInstantBalance?
    let account: WooPaymentsAccountDepositSummary
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
    let depositsDisabled: Bool
    let depositsBlocked: Bool
    let depositsSchedule: WooPaymentsDepositsSchedule
    let defaultCurrency: String

    enum CodingKeys: String, CodingKey {
        case depositsDisabled = "deposits_disabled"
        case depositsBlocked = "deposits_blocked"
        case depositsSchedule = "deposits_schedule"
        case defaultCurrency = "default_currency"
    }
}

public struct WooPaymentsDepositsSchedule: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let delayDays: Int
    let interval: String
}

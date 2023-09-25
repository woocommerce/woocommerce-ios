import Foundation
import Codegen

public struct WCPayDepositsOverview: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let lastDeposit: WCPayDeposit?
    let nextDeposit: WCPayDeposit?
    let availableBalance: WCPayBalance?
    let pendingBalance: WCPayBalance?
    let instantBalance: WCPayInstantBalance?
    let account: WCPayAccountDepositSummary
}

public struct WCPayDeposit: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
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

public struct WCPayBalance: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let amount: Int
    let currency: String
    let sourceTypes: WCPaySourceTypes
    let depositsCount: Int?

    enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case sourceTypes = "source_types"
        case depositsCount = "deposits_count"
    }
}

public struct WCPaySourceTypes: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let card: Int
}

public struct WCPayInstantBalance: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    // Define properties for the 'instant_balance' object if needed.
}

public struct WCPayAccountDepositSummary: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let depositsDisabled: Bool
    let depositsBlocked: Bool
    let depositsSchedule: WCPayDepositsSchedule
    let defaultCurrency: String

    enum CodingKeys: String, CodingKey {
        case depositsDisabled = "deposits_disabled"
        case depositsBlocked = "deposits_blocked"
        case depositsSchedule = "deposits_schedule"
        case defaultCurrency = "default_currency"
    }
}

public struct WCPayDepositsSchedule: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    let delayDays: Int
    let interval: String
}

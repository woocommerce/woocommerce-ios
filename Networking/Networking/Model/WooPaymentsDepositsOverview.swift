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
    let type: WooPaymentsDepositType
    let amount: Int
    let status: WooPaymentsDepositStatus
    let bankAccount: String
    let currency: String
    let automatic: Bool
    let fee: Int
    let feePercentage: Int
    let created: Int
}

/// originates from https://github.com/Automattic/woocommerce-payments-server/blob/899963c61d9ad1c1aa5306087b8bb7ea253e66a0/server/wp-content/rest-api-plugins/endpoints/wcpay/class-deposits-controller.php#L753
public enum WooPaymentsDepositType: String, Codable, Equatable {
    case withdrawal
    case deposit
}

/// originates from https://stripe.com/docs/api/payouts/object
/// with additions in WooPayments e.g. https://github.com/Automattic/woocommerce-payments-server/blob/899963c61d9ad1c1aa5306087b8bb7ea253e66a0/server/wp-content/rest-api-plugins/endpoints/wcpay/utils/class-deposit-utils.php#L141
public enum WooPaymentsDepositStatus: String, Codable, Equatable {
    case estimated
    case pending
    case inTransit = "in_transit"
    case paid
    case canceled
    case failed
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
public enum WooPaymentsDepositInterval: String, Codable, Equatable {
    case daily
    case weekly
    case monthly
    case manual
}

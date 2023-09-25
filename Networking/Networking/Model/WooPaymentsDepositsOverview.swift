import Foundation
import Codegen

public struct WooPaymentsDepositsOverview: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let deposit: WooPaymentsCurrencyDeposits
    public let balance: WooPaymentsCurrencyBalances
    public let account: WooPaymentsAccountDepositSummary
}

public struct WooPaymentsCurrencyDeposits: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let lastPaid: [WooPaymentsDeposit]
    public let nextScheduled: [WooPaymentsDeposit]
    public let lastManualDeposits: [WooPaymentsDeposit]
}

public struct WooPaymentsDeposit: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let id: String
    public let date: Date
    public let type: WooPaymentsDepositType
    public let amount: Int
    public let status: WooPaymentsDepositStatus
    public let bankAccount: String
    public let currency: String
    public let automatic: Bool
    public let fee: Int
    public let feePercentage: Int
    public let created: Int
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
    public let pending: [WooPaymentsBalance]
    public let available: [WooPaymentsBalance]
    public let instant: [WooPaymentsBalance]
}

public struct WooPaymentsBalance: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let amount: Int
    public let currency: String
    public let sourceTypes: WooPaymentsSourceTypes
    public let depositsCount: Int?

    public enum CodingKeys: String, CodingKey {
        case amount
        case currency
        case sourceTypes = "source_types"
        case depositsCount = "deposits_count"
    }
}

public struct WooPaymentsSourceTypes: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let card: Int
}

public struct WooPaymentsAccountDepositSummary: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let depositsEnabled: Bool
    public let depositsBlocked: Bool
    public let depositsSchedule: WooPaymentsDepositsSchedule
    public let defaultCurrency: String

    public enum CodingKeys: String, CodingKey {
        case depositsEnabled = "deposits_enabled"
        case depositsBlocked = "deposits_blocked"
        case depositsSchedule = "deposits_schedule"
        case defaultCurrency = "default_currency"
    }
}

public struct WooPaymentsDepositsSchedule: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let delayDays: Int
    public let interval: WooPaymentsDepositInterval
}

/// originally from https://stripe.com/docs/api/accounts/object#account_object-settings-payouts-schedule-interval
public enum WooPaymentsDepositInterval: String, Codable, Equatable {
    case daily
    case weekly
    case monthly
    case manual
}

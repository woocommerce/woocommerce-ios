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
    public let lastManualDeposits: [WooPaymentsManualDeposit]

    enum CodingKeys: String, CodingKey {
        case lastPaid = "last_paid"
        case nextScheduled = "next_scheduled"
        case lastManualDeposits = "last_manual_deposits"
    }
}

public struct WooPaymentsDeposit: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let id: String
    public let date: Date
    public let type: WooPaymentsDepositType
    public let amount: Int
    public let status: WooPaymentsDepositStatus
    public let bankAccount: String?
    public let currency: String
    public let automatic: Bool
    public let fee: Int
    public let feePercentage: Int
    public let created: Int

    enum CodingKeys: String, CodingKey {
        case id
        case date
        case type
        case amount
        case status
        case bankAccount = "bank_account"
        case currency
        case automatic
        case fee
        case feePercentage = "fee_percentage"
        case created
    }
}

public struct WooPaymentsManualDeposit: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let currency: String
    public let date: Date

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currency = try container.decode(String.self, forKey: .currency)
        let dateString = try container.decode(String.self, forKey: .date)

        // For some reason, the date here is an ISO 8601 string not a milliseconds timestamp.
        // Manual date parsing allows us to continue to parse the whole response with a single decoder.
        let isoDateFormatter = ISO8601DateFormatter()
//        isoDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
//        isoDateFormatter.formatOptions = [
//            .withFullDate,
//            .withFullTime,
//            .withDashSeparatorInDate,
//            .withFractionalSeconds]

        guard let date = isoDateFormatter.date(from: dateString) else {
            throw DecodingError.typeMismatch(Date.self, .init(codingPath: [CodingKeys.date],
                                                              debugDescription: "Expected ISO8601 string",
                                                              underlyingError: nil))
        }
        self.date = date
    }
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

    enum CodingKeys: String, CodingKey {
        case delayDays = "delay_days"
        case interval
    }
}

/// originally from https://stripe.com/docs/api/accounts/object#account_object-settings-payouts-schedule-interval
public enum WooPaymentsDepositInterval: String, Codable, Equatable {
    case daily
    case weekly
    case monthly
    case manual
}

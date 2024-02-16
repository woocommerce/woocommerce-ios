import Foundation
import Codegen

public struct WooPaymentsDepositsOverview: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let deposit: WooPaymentsCurrencyDeposits
    public let balance: WooPaymentsCurrencyBalances
    public let account: WooPaymentsAccountDepositSummary

    public init(deposit: WooPaymentsCurrencyDeposits,
                balance: WooPaymentsCurrencyBalances,
                account: WooPaymentsAccountDepositSummary) {
        self.deposit = deposit
        self.balance = balance
        self.account = account
    }
}

public struct WooPaymentsCurrencyDeposits: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let lastPaid: [WooPaymentsDeposit]
    public let lastManualDeposits: [WooPaymentsManualDeposit]

    public init(lastPaid: [WooPaymentsDeposit],
                lastManualDeposits: [WooPaymentsManualDeposit]) {
        self.lastPaid = lastPaid
        self.lastManualDeposits = lastManualDeposits
    }

    enum CodingKeys: String, CodingKey {
        case lastPaid = "last_paid"
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

    public init(id: String,
                date: Date,
                type: WooPaymentsDepositType,
                amount: Int,
                status: WooPaymentsDepositStatus,
                bankAccount: String?,
                currency: String,
                automatic: Bool,
                fee: Int,
                feePercentage: Int,
                created: Int) {
        self.id = id
        self.date = date
        self.type = type
        self.amount = amount
        self.status = status
        self.bankAccount = bankAccount
        self.currency = currency
        self.automatic = automatic
        self.fee = fee
        self.feePercentage = feePercentage
        self.created = created
    }

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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.date = try container.decode(Date.self, forKey: .date)
        self.type = try container.decode(WooPaymentsDepositType.self, forKey: .type)
        self.amount = try container.decode(Int.self, forKey: .amount)
        self.status = container.failsafeDecodeIfPresent(WooPaymentsDepositStatus.self, forKey: .status) ?? .unknown
        self.bankAccount = try container.decodeIfPresent(String.self, forKey: .bankAccount)
        self.currency = try container.decode(String.self, forKey: .currency)
        self.automatic = try container.decode(Bool.self, forKey: .automatic)
        self.fee = try container.decode(Int.self, forKey: .fee)
        self.feePercentage = try container.decode(Int.self, forKey: .feePercentage)
        self.created = try container.decode(Int.self, forKey: .created)
    }
}

public struct WooPaymentsManualDeposit: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let currency: String
    public let date: Date

    public init(currency: String, date: Date) {
        self.currency = currency
        self.date = date
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        currency = try container.decode(String.self, forKey: .currency)
        let dateString = try container.decode(String.self, forKey: .date)

        // For some reason, the date here is a string not a milliseconds timestamp.
        // Manual date parsing allows us to continue to parse the whole response with a single decoder.
        // ISO8601DateFormatter with custom options should be a better choice here, but didn't work.
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        guard let date = dateFormatter.date(from: dateString) else {
            throw DecodingError.typeMismatch(Date.self, .init(codingPath: [CodingKeys.date],
                                                              debugDescription: "Expected ISO8601 string",
                                                              underlyingError: nil))
        }
        self.date = date
    }
}

/// originates from
// https://github.com/Automattic/woocommerce-payments-server/blob/899963c61d9ad1c1aa5306087b8bb7ea253e66a0/server/
// wp-content/rest-api-plugins/endpoints/wcpay/class-deposits-controller.php#L753
public enum WooPaymentsDepositType: String, Codable, Equatable, GeneratedFakeable, GeneratedCopiable {
    case withdrawal
    case deposit
}

/// originates from https://stripe.com/docs/api/payouts/object
/// with additions in WooPayments e.g.
// https://github.com/Automattic/woocommerce-payments-server/blob/899963c61d9ad1c1aa5306087b8bb7ea253e66a0/
// server/wp-content/rest-api-plugins/endpoints/wcpay/utils/class-deposit-utils.php#L141
public enum WooPaymentsDepositStatus: String, Codable, Equatable, GeneratedFakeable, GeneratedCopiable {
    case estimated
    case pending
    case inTransit = "in_transit"
    case paid
    case canceled
    case failed
    case unknown
}

public struct WooPaymentsCurrencyBalances: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let pending: [WooPaymentsBalance]
    public let available: [WooPaymentsBalance]
    public let instant: [WooPaymentsBalance]

    public init(pending: [WooPaymentsBalance], available: [WooPaymentsBalance], instant: [WooPaymentsBalance]) {
        self.pending = pending
        self.available = available
        self.instant = instant
    }
}

public struct WooPaymentsBalance: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let amount: Int
    public let currency: String

    public init(amount: Int, currency: String) {
        self.amount = amount
        self.currency = currency
    }

    public enum CodingKeys: String, CodingKey {
        case amount
        case currency
    }
}

public struct WooPaymentsAccountDepositSummary: Codable, GeneratedFakeable, GeneratedCopiable, Equatable {
    public let depositsEnabled: Bool
    public let depositsBlocked: Bool
    public let depositsSchedule: WooPaymentsDepositsSchedule
    public let defaultCurrency: String

    public init(depositsEnabled: Bool,
                depositsBlocked: Bool,
                depositsSchedule: WooPaymentsDepositsSchedule,
                defaultCurrency: String) {
        self.depositsEnabled = depositsEnabled
        self.depositsBlocked = depositsBlocked
        self.depositsSchedule = depositsSchedule
        self.defaultCurrency = defaultCurrency
    }

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

    public init(delayDays: Int, interval: WooPaymentsDepositInterval) {
        self.delayDays = delayDays
        self.interval = interval
    }

    enum CodingKeys: String, CodingKey {
        case delayDays = "delay_days"
        case interval
        case weeklyAnchor = "weekly_anchor"
        case monthlyAnchor = "monthly_anchor"
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        delayDays = try container.decode(Int.self, forKey: .delayDays)
        let weeklyAnchor = try container.decodeIfPresent(WooPaymentsDepositInterval.Weekday.self, forKey: .weeklyAnchor)
        let monthlyAnchor = try container.decodeIfPresent(Int.self, forKey: .monthlyAnchor)
        let intervalKey = try container.decode(WooPaymentsDepositInterval.EnumKey.self, forKey: .interval)

        guard let interval = WooPaymentsDepositInterval(key: intervalKey,
                                                        weeklyAnchor: weeklyAnchor,
                                                        monthlyAnchor: monthlyAnchor) else {
            throw DecodingError.dataCorrupted(.init(codingPath: [CodingKeys.interval],
                                                    debugDescription: "Could not decode deposit schedule interval"))
        }
        self.interval = interval
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(delayDays, forKey: .delayDays)
        try container.encode(interval.key, forKey: .interval)
        switch interval {
        case .weekly(let weekday):
            try container.encode(weekday.rawValue, forKey: .weeklyAnchor)
        case .monthly(let dayOfMonth):
            try container.encode(dayOfMonth, forKey: .monthlyAnchor)
        default:
            break
        }
    }
}

/// originally from https://stripe.com/docs/api/accounts/object#account_object-settings-payouts-schedule-interval
public enum WooPaymentsDepositInterval: Equatable, GeneratedFakeable, GeneratedCopiable {
    case daily
    case weekly(anchor: Weekday)
    case monthly(anchor: Int)
    case manual

    init?(key: EnumKey, weeklyAnchor: Weekday?, monthlyAnchor: Int?) {
        switch (key, weeklyAnchor, monthlyAnchor) {
        case (.daily, _, _):
            self = .daily
        case (.weekly, .some(let anchor), _):
            self = .weekly(anchor: anchor)
        case (.monthly, _, .some(let anchor)):
            self = .monthly(anchor: anchor)
        case (.manual, _, _):
            self = .manual
        default:
            return nil
        }
    }

    enum EnumKey: String, Codable {
        case daily
        case weekly
        case monthly
        case manual
    }

    var key: String {
        switch self {
        case .daily:
            return EnumKey.daily.rawValue
        case .weekly:
            return EnumKey.weekly.rawValue
        case .monthly:
            return EnumKey.monthly.rawValue
        case .manual:
            return EnumKey.manual.rawValue
        }
    }

    public enum Weekday: String, Decodable {
        case sunday
        case monday
        case tuesday
        case wednesday
        case thursday
        case friday
        case saturday

        public var localizedName: String {
            let dateFormatter = DateFormatter()
            dateFormatter.locale = .autoupdatingCurrent
            dateFormatter.calendar = Calendar(identifier: .gregorian)

            // This array is always Sunday-indexed, regardless of locale
            guard let dayNames = dateFormatter.standaloneWeekdaySymbols,
                  let localizedDayName = dayNames[safe: dayIndex] else {
                // This shouldn't really happen... but at least it'll be sort of understandable.
                return rawValue
            }

            return localizedDayName
        }

        private var dayIndex: Int {
            switch self {
            case .sunday:
                return 0
            case .monday:
                return 1
            case .tuesday:
                return 2
            case .wednesday:
                return 3
            case .thursday:
                return 4
            case .friday:
                return 5
            case .saturday:
                return 6
            }
        }
    }
}

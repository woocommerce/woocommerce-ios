import Foundation
import Codegen

/// Represents the subscription settings extracted from product meta data for a Subscription-type Product.
public struct ProductSubscription: Decodable, Equatable, GeneratedFakeable, GeneratedCopiable {
    /// Subscription automatically expires after this number of subscription periods.
    ///
    /// For example, subscription with period of `month` and length of "2" expires after 2 months. Subscription with length of "0" never expires.
    public let length: String

    /// Subscription period.
    public let period: SubscriptionPeriod

    /// Subscription billing interval for the subscription period.
    public let periodInterval: String

    /// Regular price of the subscription.
    public let price: String

    /// Optional amount to be charged at the outset of the subscription. Empty string if no
    public let signUpFee: String

    /// Length of the free trial period. (Length is "0" for no free trial.)
    public let trialLength: String

    /// Period of the free trial, if any.
    public let trialPeriod: SubscriptionPeriod

    /// Only charge shipping once on the initial order if `true`.
    public let oneTimeShipping: Bool

    /// Subscription Renewal Synchronization date
    public let paymentSyncDate: String

    public init(length: String,
                period: SubscriptionPeriod,
                periodInterval: String,
                price: String,
                signUpFee: String,
                trialLength: String,
                trialPeriod: SubscriptionPeriod,
                oneTimeShipping: Bool,
                paymentSyncDate: String) {
        self.length = length
        self.period = period
        self.periodInterval = periodInterval
        self.price = price
        self.signUpFee = signUpFee
        self.trialLength = trialLength
        self.trialPeriod = trialPeriod
        self.oneTimeShipping = oneTimeShipping
        self.paymentSyncDate = paymentSyncDate
    }

    /// Custom decoding to use default value when JSON doesn't have a key present
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        length = try container.decodeIfPresent(String.self, forKey: .length) ?? "0"
        period = try container.decodeIfPresent(SubscriptionPeriod.self, forKey: .period) ?? .month
        periodInterval = try container.decodeIfPresent(String.self, forKey: .periodInterval) ?? "0"
        price = try container.decodeIfPresent(String.self, forKey: .price) ?? "0"
        signUpFee = try container.decodeIfPresent(String.self, forKey: .signUpFee) ?? "0"
        trialLength = try container.decodeIfPresent(String.self, forKey: .trialLength) ?? "0"
        trialPeriod = try container.decodeIfPresent(SubscriptionPeriod.self, forKey: .trialPeriod) ?? .day
        oneTimeShipping = {
            guard let stringValue = try? container.decodeIfPresent(String.self, forKey: .oneTimeShipping) else {
                return false
            }

            return stringValue == Constants.yes
        }()
        paymentSyncDate = try container.decodeIfPresent(String.self, forKey: .paymentSyncDate) ?? "0"
    }

    func toKeyValuePairs() -> [KeyValuePair] {
        [
            .init(key: CodingKeys.length.rawValue, value: length),
            .init(key: CodingKeys.period.rawValue, value: period.rawValue),
            .init(key: CodingKeys.periodInterval.rawValue, value: periodInterval),
            .init(key: CodingKeys.price.rawValue, value: price),
            .init(key: CodingKeys.signUpFee.rawValue, value: signUpFee),
            .init(key: CodingKeys.trialLength.rawValue, value: trialLength),
            .init(key: CodingKeys.trialPeriod.rawValue, value: trialPeriod.rawValue),
            .init(key: CodingKeys.oneTimeShipping.rawValue, value: oneTimeShipping ? Constants.yes : Constants.no),
            .init(key: CodingKeys.paymentSyncDate.rawValue, value: paymentSyncDate),
        ]
    }
}

// MARK: Coding Keys
//
private extension ProductSubscription {
    enum CodingKeys: String, CodingKey {
        case length             = "_subscription_length"
        case period             = "_subscription_period"
        case periodInterval     = "_subscription_period_interval"
        case price              = "_subscription_price"
        case signUpFee          = "_subscription_sign_up_fee"
        case trialLength        = "_subscription_trial_length"
        case trialPeriod        = "_subscription_trial_period"
        case oneTimeShipping    = "_subscription_one_time_shipping"
        case paymentSyncDate    = "_subscription_payment_sync_date"
    }
}

/// Represents all possible subscription periods
///
public enum SubscriptionPeriod: String, Decodable, GeneratedFakeable, CaseIterable {
    case day
    case week
    case month
    case year
}

/// Used to encode items as key value pairs
///
struct KeyValuePair: Encodable, Equatable {
    let key: String
    let value: String
}

private enum Constants {
    static let yes = "yes"
    static let no = "no"
}

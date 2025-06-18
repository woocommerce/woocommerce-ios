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

    /// Subscription Renewal Synchronization month
    public let paymentSyncMonth: String

    public init(length: String,
                period: SubscriptionPeriod,
                periodInterval: String,
                price: String,
                signUpFee: String,
                trialLength: String,
                trialPeriod: SubscriptionPeriod,
                oneTimeShipping: Bool,
                paymentSyncDate: String,
                paymentSyncMonth: String) {
        self.length = length
        self.period = period
        self.periodInterval = periodInterval
        self.price = price
        self.signUpFee = signUpFee
        self.trialLength = trialLength
        self.trialPeriod = trialPeriod
        self.oneTimeShipping = oneTimeShipping
        self.paymentSyncDate = paymentSyncDate
        self.paymentSyncMonth = paymentSyncMonth
    }

    /// Custom decoding to use default value when JSON doesn't have a key present
    ///
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        length = container.failsafeDecodeIfPresent(stringForKey: .length) ?? "0"
        period = try container.decodeIfPresent(SubscriptionPeriod.self, forKey: .period) ?? .month
        periodInterval = container.failsafeDecodeIfPresent(stringForKey: .periodInterval) ?? "1"
        price = container.failsafeDecodeIfPresent(stringForKey: .price) ?? "0"
        signUpFee = container.failsafeDecodeIfPresent(stringForKey: .signUpFee) ?? "0"
        trialLength = container.failsafeDecodeIfPresent(stringForKey: .trialLength) ?? "0"
        trialPeriod = try container.decodeIfPresent(SubscriptionPeriod.self, forKey: .trialPeriod) ?? .day
        oneTimeShipping = {
            guard let stringValue = try? container.decodeIfPresent(String.self, forKey: .oneTimeShipping) else {
                return false
            }

            return stringValue == Constants.yes
        }()

        if let paymentSyncDateString = try? container.decodeIfPresent(String.self, forKey: .paymentSyncDate) {
            paymentSyncDate = paymentSyncDateString
            paymentSyncMonth = ""
        } else if let paymentSync = try? container.decodeIfPresent(SubscriptionPaymentSyncDate.self, forKey: .paymentSyncDate) {
            paymentSyncDate = paymentSync.day
            paymentSyncMonth = paymentSync.month
        } else {
            paymentSyncDate = "0"
            paymentSyncMonth = ""
        }
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
            .init(key: CodingKeys.oneTimeShipping.rawValue, value: oneTimeShipping ? Constants.yes : Constants.no)
            /// We are not encoding `paymentSyncDate` and `paymentSyncMonth` as we don't support editing yet.
            /// When we support editing we may have to encode these values into dict if the subscription is yearly.
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

private struct SubscriptionPaymentSyncDate: Decodable {
    let day: String
    let month: String

    /// Custom decoding to handle String and Int types
    ///
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        day = container.failsafeDecodeIfPresent(targetType: String.self,
                                                       forKey: .day,
                                                       alternativeTypes: [.integer(transform: {  String($0) })]) ?? ""

        month = container.failsafeDecodeIfPresent(targetType: String.self,
                                                       forKey: .month,
                                                       alternativeTypes: [.integer(transform: {  String($0) })]) ?? ""
    }

    enum CodingKeys: String, CodingKey {
        case day
        case month
    }
}

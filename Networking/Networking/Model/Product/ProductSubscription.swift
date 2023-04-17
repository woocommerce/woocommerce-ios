import Foundation
import Codegen

/// Represents the subscription settings extracted from product meta data for a Subscription-type Product.
public struct ProductSubscription: Decodable, Equatable, GeneratedFakeable {
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

    public init(length: String,
                period: SubscriptionPeriod,
                periodInterval: String,
                price: String,
                signUpFee: String,
                trialLength: String,
                trialPeriod: SubscriptionPeriod) {
        self.length = length
        self.period = period
        self.periodInterval = periodInterval
        self.price = price
        self.signUpFee = signUpFee
        self.trialLength = trialLength
        self.trialPeriod = trialPeriod
    }
}

// MARK: Coding Keys
//
private extension ProductSubscription {
    enum CodingKeys: String, CodingKey {
        case length         = "_subscription_length"
        case period         = "_subscription_period"
        case periodInterval = "_subscription_period_interval"
        case price          = "_subscription_price"
        case signUpFee      = "_subscription_sign_up_fee"
        case trialLength    = "_subscription_trial_length"
        case trialPeriod    = "_subscription_trial_period"
    }
}

/// Represents all possible subscription periods
///
public enum SubscriptionPeriod: String, Codable, GeneratedFakeable {
    case day
    case week
    case month
    case year
}

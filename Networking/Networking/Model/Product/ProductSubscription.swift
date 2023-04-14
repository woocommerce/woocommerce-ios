import Foundation

/// Represents the subscription settings extracted from product meta data for a Subscription-type Product.
public struct ProductSubscription: Decodable, Equatable {
    /// Subscription automatically expires after this number of subscription periods.
    ///
    /// For example, subscription with period of `month` and length of "2" expires after 2 months. Subscription with length of "0" never expires.
    public let length: String

    /// Subscription period.
    public let period: String

    /// Subscription billing interval for the subscription period.
    public let periodInterval: String

    /// Regular price of the subscription.
    public let price: String

    /// Optional amount to be charged at the outset of the subscription.
    public let signUpFee: String

    /// Length of the free trial period, if any.
    public let trialLength: String

    /// Period of the free trial, if any.
    public let trialPeriod: String

    public init(length: String,
                period: String,
                periodInterval: String,
                price: String,
                signUpFee: String,
                trialLength: String,
                trialPeriod: String) {
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

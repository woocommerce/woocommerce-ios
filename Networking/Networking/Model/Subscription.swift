import Foundation

/// Represents a Subscription entity
///
public struct Subscription: Decodable, Equatable {
    public let siteID: Int64

    /// Unique identifier for the Subscription.
    public let subscriptionID: Int64

    /// Parent/initial order ID for the subscription.
    public let parentID: Int64

    /// Subscription status. Default is `pending`.
    public let status: SubscriptionStatus

    /// Currency the subscription was created with, in ISO format.
    public let currency: String

    /// The subscription's billing period.
    public let billingPeriod: SubscriptionPeriod

    /// The number of billing periods between subscription renewals.
    public let billingInterval: String

    /// Grand total.
    public let total: String

    /// The subscription's start date in GMT.
    public let startDate: Date

    /// The subscription's end date in GMT.
    public let endDate: Date

    /// Subscription struct initializer.
    ///
    public init(siteID: Int64,
                subscriptionID: Int64,
                parentID: Int64,
                status: SubscriptionStatus,
                currency: String,
                billingPeriod: SubscriptionPeriod,
                billingInterval: String,
                total: String,
                startDate: Date,
                endDate: Date) {
        self.siteID = siteID
        self.subscriptionID = subscriptionID
        self.parentID = parentID
        self.status = status
        self.currency = currency
        self.billingPeriod = billingPeriod
        self.billingInterval = billingInterval
        self.total = total
        self.startDate = startDate
        self.endDate = endDate
    }

    /// The public initializer for Subscription.
    ///
    public init(from decoder: Decoder) throws {
        guard let siteID = decoder.userInfo[.siteID] as? Int64 else {
            throw SubscriptionDecodingError.missingSiteID
        }

        let container = try decoder.container(keyedBy: CodingKeys.self)

        let subscriptionID = try container.decode(Int64.self, forKey: .subscriptionID)
        let parentID = try container.decode(Int64.self, forKey: .parentID)
        let status = try container.decode(SubscriptionStatus.self, forKey: .status)
        let currency = try container.decode(String.self, forKey: .currency)
        let billingPeriod = try container.decode(SubscriptionPeriod.self, forKey: .billingPeriod)
        let billingInterval = try container.decode(String.self, forKey: .billingInterval)
        let total = try container.decode(String.self, forKey: .total)
        let startDate = try container.decode(Date.self, forKey: .startDate)
        let endDate = try container.decode(Date.self, forKey: .endDate)

        self.init(siteID: siteID,
                  subscriptionID: subscriptionID,
                  parentID: parentID,
                  status: status,
                  currency: currency,
                  billingPeriod: billingPeriod,
                  billingInterval: billingInterval,
                  total: total,
                  startDate: startDate,
                  endDate: endDate)
    }
}

// MARK: Coding Keys
//
internal extension Subscription {
    enum CodingKeys: String, CodingKey {
        case subscriptionID     = "id"
        case parentID           = "parent_id"
        case status             = "status"
        case currency           = "currency"
        case billingPeriod      = "billing_period"
        case billingInterval    = "billing_interval"
        case total              = "total"
        case startDate          = "start_date_gmt"
        case endDate            = "end_date_gmt"
    }
}

// MARK: - Decoding Errors
//
enum SubscriptionDecodingError: Error {
    case missingSiteID
}

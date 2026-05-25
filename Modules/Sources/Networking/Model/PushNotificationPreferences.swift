import Foundation

/// Per-user push notification preferences served by the WooCommerce plugin under
/// `wc-push-notifications/preferences`.
///
/// The same type is used for the full GET response and for partial POST bodies:
/// every field is `Optional` and the custom `encode(to:)` implementation drops
/// `nil` keys via `encodeIfPresent`. Callers building a partial update set only
/// the sub-fields they want to change; the server deep-merges and returns the
/// fully populated, sanitized result.
///
public struct PushNotificationPreferences: Codable, Equatable, Sendable {

    public let storeOrder: StoreOrder?
    public let storeReview: StoreReview?
    public let storeStock: StoreStock?

    public init(storeOrder: StoreOrder? = nil,
                storeReview: StoreReview? = nil,
                storeStock: StoreStock? = nil) {
        self.storeOrder = storeOrder
        self.storeReview = storeReview
        self.storeStock = storeStock
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.storeOrder = try container.decodeIfPresent(StoreOrder.self, forKey: .storeOrder)
        self.storeReview = try container.decodeIfPresent(StoreReview.self, forKey: .storeReview)
        self.storeStock = try container.decodeIfPresent(StoreStock.self, forKey: .storeStock)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(storeOrder, forKey: .storeOrder)
        try container.encodeIfPresent(storeReview, forKey: .storeReview)
        try container.encodeIfPresent(storeStock, forKey: .storeStock)
    }

    enum CodingKeys: String, CodingKey {
        case storeOrder = "store_order"
        case storeReview = "store_review"
        case storeStock = "store_stock"
    }
}

public extension PushNotificationPreferences {

    /// Preferences for new-order notifications.
    ///
    /// Callers always send a complete `StoreOrder` when updating — the client
    /// never produces a partial `store_order` body. Two valid client-controlled
    /// states:
    /// - `enabled: false, minAmount: nil` — off, threshold cleared.
    /// - `enabled: true, minAmount: <positive>` — on with a specific threshold.
    ///
    /// The server's default for fresh users (`enabled: true, minAmount: nil`)
    /// is still decoded correctly on reads.
    ///
    struct StoreOrder: Codable, Equatable, Sendable {

        /// Master toggle for new-order notifications.
        public let enabled: Bool

        /// Order-total threshold below which notifications are suppressed.
        /// `nil` is sent on the wire as JSON `null`, which the server interprets
        /// as "no threshold" (notify on every order when `enabled` is true).
        public let minAmount: Decimal?

        public init(enabled: Bool, minAmount: Decimal? = nil) {
            self.enabled = enabled
            self.minAmount = minAmount
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(enabled, forKey: .enabled)
            // Use `encode` (not `encodeIfPresent`) so `nil` is written as JSON `null`
            // — the server interprets explicit null as "clear the threshold".
            if let minAmount {
                try container.encode(minAmount, forKey: .minAmount)
            } else {
                try container.encodeNil(forKey: .minAmount)
            }
        }

        enum CodingKeys: String, CodingKey {
            case enabled
            case minAmount = "min_amount"
        }
    }

    /// Preferences for product-review notifications.
    ///
    struct StoreReview: Codable, Equatable, Sendable {

        /// Master toggle for review notifications.
        public let enabled: Bool?

        /// Maximum star rating that triggers a notification. Server clamps to `1...5`.
        /// `nil` is sent on the wire as JSON `null`, which the server interprets as
        /// "notify on every review" (matches the "All new reviews" radio option).
        public let maxRating: Int?

        public init(enabled: Bool? = nil, maxRating: Int? = nil) {
            self.enabled = enabled
            self.maxRating = maxRating
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
            self.maxRating = try container.decodeIfPresent(Int.self, forKey: .maxRating)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(enabled, forKey: .enabled)
            // Use `encode`/`encodeNil` (not `encodeIfPresent`) so `nil` is written as
            // JSON `null` — the server interprets explicit null as "clear the rating".
            // Without this, omitting the key would mean "no change", and the user
            // could never switch from "Only low-rated reviews" back to "All new reviews".
            if let maxRating {
                try container.encode(maxRating, forKey: .maxRating)
            } else {
                try container.encodeNil(forKey: .maxRating)
            }
        }

        enum CodingKeys: String, CodingKey {
            case enabled
            case maxRating = "max_rating"
        }
    }

    /// Preferences for stock-event notifications.
    ///
    struct StoreStock: Codable, Equatable, Sendable {

        /// Master toggle for stock notifications.
        public let enabled: Bool?

        /// Notify when stock crosses the site-level low-stock threshold.
        public let lowStock: Bool?

        /// Notify when stock reaches the site-level no-stock amount.
        public let outOfStock: Bool?

        /// Notify when an order causes a backordered purchase (off by default).
        public let onBackorder: Bool?

        public init(enabled: Bool? = nil,
                    lowStock: Bool? = nil,
                    outOfStock: Bool? = nil,
                    onBackorder: Bool? = nil) {
            self.enabled = enabled
            self.lowStock = lowStock
            self.outOfStock = outOfStock
            self.onBackorder = onBackorder
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
            self.lowStock = try container.decodeIfPresent(Bool.self, forKey: .lowStock)
            self.outOfStock = try container.decodeIfPresent(Bool.self, forKey: .outOfStock)
            self.onBackorder = try container.decodeIfPresent(Bool.self, forKey: .onBackorder)
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(enabled, forKey: .enabled)
            try container.encodeIfPresent(lowStock, forKey: .lowStock)
            try container.encodeIfPresent(outOfStock, forKey: .outOfStock)
            try container.encodeIfPresent(onBackorder, forKey: .onBackorder)
        }

        enum CodingKeys: String, CodingKey {
            case enabled
            case lowStock = "low_stock"
            case outOfStock = "out_of_stock"
            case onBackorder = "on_backorder"
        }
    }
}

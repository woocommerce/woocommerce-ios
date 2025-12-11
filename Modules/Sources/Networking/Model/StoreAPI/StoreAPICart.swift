import Foundation

/// Represents a WooCommerce Store API Cart response.
///
public struct StoreAPICart: Decodable, Equatable {
    /// List of items in the cart.
    public let items: [StoreAPICartItem]

    /// Total number of items in the cart.
    public let itemsCount: Int

    /// Total number of items (including quantities) in the cart.
    public let itemsWeight: Double

    /// List of applied coupons.
    public let coupons: [StoreAPICartCoupon]

    /// Whether the cart needs payment (total > 0).
    public let needsPayment: Bool

    /// Whether the cart needs shipping.
    public let needsShipping: Bool

    /// Cart totals.
    public let totals: StoreAPICartTotals

    public init(
        items: [StoreAPICartItem],
        itemsCount: Int,
        itemsWeight: Double,
        coupons: [StoreAPICartCoupon],
        needsPayment: Bool,
        needsShipping: Bool,
        totals: StoreAPICartTotals
    ) {
        self.items = items
        self.itemsCount = itemsCount
        self.itemsWeight = itemsWeight
        self.coupons = coupons
        self.needsPayment = needsPayment
        self.needsShipping = needsShipping
        self.totals = totals
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        items = try container.decode([StoreAPICartItem].self, forKey: .items)
        itemsCount = try container.decode(Int.self, forKey: .itemsCount)
        itemsWeight = try container.decodeIfPresent(Double.self, forKey: .itemsWeight) ?? 0
        coupons = try container.decode([StoreAPICartCoupon].self, forKey: .coupons)
        needsPayment = try container.decode(Bool.self, forKey: .needsPayment)
        needsShipping = try container.decode(Bool.self, forKey: .needsShipping)
        totals = try container.decode(StoreAPICartTotals.self, forKey: .totals)
    }
}

private extension StoreAPICart {
    enum CodingKeys: String, CodingKey {
        case items
        case itemsCount = "items_count"
        case itemsWeight = "items_weight"
        case coupons
        case needsPayment = "needs_payment"
        case needsShipping = "needs_shipping"
        case totals
    }
}

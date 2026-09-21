import Foundation

public struct POSCoupon: Equatable, Hashable {
    public let id: POSItemIdentifier
    public let code: String
    public let summary: String
    public var dateExpires: Date?
    /// Whether the coupon discounts the whole cart (percent or fixed-cart type with no
    /// product or category restrictions). Whole-cart coupons never discount custom
    /// amounts (order fees), so POS warns about it on the custom amount rows.
    public let appliesToWholeCart: Bool

    public init(id: POSItemIdentifier,
                code: String,
                summary: String = "",
                dateExpires: Date? = nil,
                appliesToWholeCart: Bool = false) {
        self.id = id
        self.code = code
        self.summary = summary
        self.dateExpires = dateExpires
        self.appliesToWholeCart = appliesToWholeCart
    }

    public var isExpired: Bool {
        guard let dateExpires else {
            return false
        }
        return dateExpires <= Date()
    }
}

public extension Coupon {
    /// The core discount types known to apply to the whole cart. Deliberately an
    /// allow-list: plugin-provided types (`.other`) may or may not discount order fees,
    /// and a false "Discount not applied" note is worse than a missing one, so unknown
    /// types are never treated as whole-cart.
    private static let wholeCartDiscountTypes: Set<DiscountType> = [.percent, .fixedCart]

    /// Whether the coupon discounts the whole cart: a percent or fixed-cart discount
    /// with no product or category restrictions.
    var appliesToWholeCart: Bool {
        Self.wholeCartDiscountTypes.contains(discountType)
            && productIds.isEmpty
            && productCategories.isEmpty
    }
}

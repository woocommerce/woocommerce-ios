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

extension Coupon {
    /// Whether the coupon discounts the whole cart: a percent or fixed-cart discount
    /// with no product or category restrictions.
    var appliesToWholeCart: Bool {
        (discountType == .percent || discountType == .fixedCart)
            && productIds.isEmpty
            && productCategories.isEmpty
    }
}

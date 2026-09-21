import Foundation

struct PointOfSaleOrderTotals: Equatable {
    // Arguably these should be unformatted, and then we can rely on the SwiftUI formatter.
    // To do that, we'd need to include Decimal amounts and the order currency in this struct.
    let cartTotal: String
    let orderTotal: String
    let taxTotal: String
    let orderTotalDecimal: Decimal
    let discountTotal: String?
    /// Formatted total of any custom amounts (order fees) on the order. `nil` when there are none,
    /// so the totals breakdown can hide the row.
    let customAmountsTotal: String?
    let couponsTotals: [PointOfSaleCouponTotal]

    init(cartTotal: String,
         orderTotal: String,
         taxTotal: String,
         orderTotalDecimal: Decimal,
         discountTotal: String? = nil,
         customAmountsTotal: String? = nil,
         couponsTotals: [PointOfSaleCouponTotal] = []) {
        self.cartTotal = cartTotal
        self.orderTotal = orderTotal
        self.taxTotal = taxTotal
        self.orderTotalDecimal = orderTotalDecimal
        self.discountTotal = discountTotal
        self.customAmountsTotal = customAmountsTotal
        self.couponsTotals = couponsTotals
    }
}

struct PointOfSaleCouponTotal: Equatable {
    let code: String
    let total: String
    /// Whether the order response shows this coupon actually produced a discount.
    let hasDiscount: Bool

    init(code: String, total: String, hasDiscount: Bool = false) {
        self.code = code
        self.total = total
        self.hasDiscount = hasDiscount
    }
}

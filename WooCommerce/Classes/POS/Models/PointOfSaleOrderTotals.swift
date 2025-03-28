import Foundation

struct PointOfSaleOrderTotals: Equatable {
    // Arguably these should be unformatted, and then we can rely on the SwiftUI formatter.
    // To do that, we'd need to include Decimal amounts and the order currency in this struct.
    let cartTotal: String
    let orderTotal: String
    let taxTotal: String
    let orderTotalDecimal: Decimal
    let couponsTotals: [PointOfSaleCouponTotal]

    init(cartTotal: String,
         orderTotal: String,
         taxTotal: String,
         orderTotalDecimal: Decimal,
         couponsTotals: [PointOfSaleCouponTotal] = []
    ) {
        self.cartTotal = cartTotal
        self.orderTotal = orderTotal
        self.taxTotal = taxTotal
        self.orderTotalDecimal = orderTotalDecimal
        self.couponsTotals = couponsTotals
    }
}

struct PointOfSaleCouponTotal: Equatable {
    let code: String
    let total: String
}

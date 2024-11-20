import Foundation

struct PointOfSaleOrderTotals: Equatable {
    // Arguably these should be unformatted, and then we can rely on the SwiftUI formatter.
    // To do that, we'd need to include Decimal amounts and the order currency in this struct.
    let cartTotal: String
    let orderTotal: String
    let taxTotal: String
}

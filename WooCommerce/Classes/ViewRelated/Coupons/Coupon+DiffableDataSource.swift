import Yosemite

extension Coupon {
    var diffableIdentifier: String {
        // Coupon ID shouldn't be 0, but if it is we can fall back to the code to reduce the risk of duplicates.
        couponID != 0 ? "\(couponID)" : "code-\(code)"
    }
}

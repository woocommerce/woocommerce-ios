import Foundation

/// `UnitInputFormatter` implementation for Coupon Code input.
///
struct CouponCodeInputFormatter: UnitInputFormatter {
    func isValid(input: String) -> Bool {
        return true
    }

    func format(input text: String?) -> String {
        return text?.uppercased() ?? ""
    }
}

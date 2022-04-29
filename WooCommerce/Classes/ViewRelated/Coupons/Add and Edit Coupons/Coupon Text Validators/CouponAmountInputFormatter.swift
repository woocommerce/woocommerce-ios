import Foundation

/// `UnitInputFormatter` implementation for Coupon Amount input.
///
struct CouponAmountInputFormatter: UnitInputFormatter {
    func isValid(input: String) -> Bool {
        guard input.isNotEmpty else {
            return false
        }
        return PriceInputFormatter().isValid(input: input)
    }

    func format(input text: String?) -> String {
        guard text == nil || text?.isEmpty == true else {
            return PriceInputFormatter().format(input: text)
        }
        return "0"
    }
}

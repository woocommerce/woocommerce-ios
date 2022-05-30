import XCTest
@testable import WooCommerce

final class CouponCodeInputFormatterTests: XCTestCase {

    private let formatter = CouponCodeInputFormatter()

    // MARK: test cases for `isValid(input:)`
    func test_a_string_is_a_valid_coupon() {
        let input = "eJfDkLmDa,349292!òàèù"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    // MARK: test cases for `format(input:)`
    func test_a_coupon_code_will_be_formatted_lowercased() {
        let input = "AbCdEfD"
        XCTAssertEqual(formatter.format(input: input), "abcdefd")
    }
}

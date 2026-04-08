import XCTest
@testable import WooCommerce

final class WooShippingPhoneValidatorTests: XCTestCase {
    func test_digits_strips_non_digits() {
        // When
        let digits = WooShippingPhoneValidator.digits(from: "+1 (234) 567-8900")

        // Then
        XCTAssertEqual(digits, "12345678900")
    }

    func test_isValid_returns_false_for_empty_phone() {
        XCTAssertFalse(WooShippingPhoneValidator.isValid(phone: "", country: "US"))
    }

    func test_isValid_returns_true_for_non_us_non_empty_phone() {
        XCTAssertTrue(WooShippingPhoneValidator.isValid(phone: "123", country: "CA"))
    }

    func test_isValid_returns_true_for_us_10_digits() {
        XCTAssertTrue(WooShippingPhoneValidator.isValid(phone: "234-567-8901", country: "US"))
    }

    func test_isValid_returns_true_for_us_11_digits_with_leading_one() {
        XCTAssertTrue(WooShippingPhoneValidator.isValid(phone: "1 (234) 567-8901", country: "US"))
    }

    func test_isValid_returns_false_for_us_11_digits_without_leading_one() {
        XCTAssertFalse(WooShippingPhoneValidator.isValid(phone: "234-567-89012", country: "US"))
    }

    func test_isValid_returns_false_for_us_short_phone() {
        XCTAssertFalse(WooShippingPhoneValidator.isValid(phone: "123-4567", country: "US"))
    }
}

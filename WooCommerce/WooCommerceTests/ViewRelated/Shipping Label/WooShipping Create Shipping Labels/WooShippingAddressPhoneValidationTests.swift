import XCTest
@testable import WooCommerce
import Yosemite

final class WooShippingAddressPhoneValidationTests: XCTestCase {
    func test_hasValidPhoneNumberForShipping_returns_false_for_empty_phone() {
        let address = makeAddress(phone: "", country: "US")

        XCTAssertFalse(address.hasValidPhoneNumberForShipping)
    }

    func test_hasValidPhoneNumberForShipping_returns_true_for_non_us_non_empty_phone() {
        let address = makeAddress(phone: "123", country: "CA")

        XCTAssertTrue(address.hasValidPhoneNumberForShipping)
    }

    func test_hasValidPhoneNumberForShipping_returns_true_for_us_10_digits() {
        let address = makeAddress(phone: "234-567-8901", country: "US")

        XCTAssertTrue(address.hasValidPhoneNumberForShipping)
    }

    func test_hasValidPhoneNumberForShipping_returns_true_for_us_11_digits_with_leading_one() {
        let address = makeAddress(phone: "1 (234) 567-8901", country: "US")

        XCTAssertTrue(address.hasValidPhoneNumberForShipping)
    }

    func test_hasValidPhoneNumberForShipping_returns_false_for_us_11_digits_without_leading_one() {
        let address = makeAddress(phone: "234-567-89012", country: "US")

        XCTAssertFalse(address.hasValidPhoneNumberForShipping)
    }

    func test_hasValidPhoneNumberForShipping_returns_false_for_us_short_phone() {
        let address = makeAddress(phone: "123-4567", country: "US")

        XCTAssertFalse(address.hasValidPhoneNumberForShipping)
    }
}

private extension WooShippingAddressPhoneValidationTests {
    func makeAddress(phone: String, country: String) -> WooShippingAddress {
        WooShippingAddress(company: "HEADQUARTERS",
                           name: "JANE DOE",
                           email: "test@example.com",
                           phone: phone,
                           country: country,
                           state: "NY",
                           address1: "15 ALGONKIN ST",
                           address2: "",
                           city: "TICONDEROGA",
                           postcode: "12883")
    }
}

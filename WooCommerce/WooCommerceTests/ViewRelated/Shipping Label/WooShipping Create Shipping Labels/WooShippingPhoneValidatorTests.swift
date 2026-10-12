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

    func test_isDestinationPhoneRequired_when_countries_differ_or_carrier_is_FedEx_then_returns_true() {
        // Given
        let cases: [(String?, String, String?)] = [("US", "CA", "usps"), ("US", "CA", nil), ("US", "US", "fedex")]

        // When
        let results = cases.map { originCountry, destinationCountry, carrierID in
            WooShippingPhoneValidator.isDestinationPhoneRequired(originCountry: originCountry,
                                                                 destinationCountry: destinationCountry,
                                                                 carrierID: carrierID)
        }

        // Then
        XCTAssertEqual(results, [true, true, true])
    }

    func test_isDestinationPhoneRequired_when_domestic_or_origin_unknown_without_FedEx_then_returns_false() {
        // Given
        let cases: [(String?, String, String?)] = [("US", "US", "usps"), ("us", "US", nil), (nil, "CA", "usps"), ("", "CA", "upsdap")]

        // When
        let results = cases.map { originCountry, destinationCountry, carrierID in
            WooShippingPhoneValidator.isDestinationPhoneRequired(originCountry: originCountry,
                                                                 destinationCountry: destinationCountry,
                                                                 carrierID: carrierID)
        }

        // Then
        XCTAssertEqual(results, [false, false, false, false])
    }

    func test_issue_when_phone_is_empty_or_whitespace_then_returns_missing_only_if_required() {
        // Given
        let phones = ["", "  \n"]

        // When / Then
        for phone in phones {
            XCTAssertEqual(WooShippingPhoneValidator.issue(phone: phone, country: "US", isRequired: true), .missing)
            XCTAssertNil(WooShippingPhoneValidator.issue(phone: phone, country: "US", isRequired: false))
        }
    }

    func test_issue_when_phone_is_entered_then_checks_format_regardless_of_requirement() {
        // Given
        let invalidPhones = [("abc", "CA"), ("---", "US"), ("123-456-7890", "US"), ("123-4567", "US")]
        let validPhones = [("234-567-8901", "US"), ("1 (234) 567-8901", "US")]

        // When / Then
        for isRequired in [true, false] {
            for (phone, country) in invalidPhones {
                XCTAssertEqual(WooShippingPhoneValidator.issue(phone: phone, country: country, isRequired: isRequired), .invalid, phone)
            }
            for (phone, country) in validPhones {
                XCTAssertNil(WooShippingPhoneValidator.issue(phone: phone, country: country, isRequired: isRequired), phone)
            }
        }
    }
}

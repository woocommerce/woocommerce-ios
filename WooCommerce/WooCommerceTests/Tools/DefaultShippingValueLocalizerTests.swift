import XCTest

@testable import WooCommerce

final class DefaultShippingValueLocalizerTests: XCTestCase {
    private let usLocale = Locale(identifier: "en_US")
    private let itLocale = Locale(identifier: "it_IT")

    func test_localizing_string_with_correct_deviceLocale_and_apiLocale() {
        // Given
        let valueWithPeriod = "1.2"
        let localizer = DefaultShippingValueLocalizer(deviceLocale: itLocale, apiLocale: usLocale)

        // When
        let localized = localizer.localized(shippingValue: valueWithPeriod)

        // Then
        XCTAssertEqual(localized, "1,2")

        // When
        let unlocalized = localizer.unLocalized(shippingValue: localized)

        // Then
        XCTAssertEqual(unlocalized, "1.2")
    }

    func test_localizing_string_with_incorrect_locales() {
        // Given
        let valueWithPeriod = "1.2"
        let localizer = DefaultShippingValueLocalizer(deviceLocale: usLocale, apiLocale: itLocale)

        // When
        let localized = localizer.localized(shippingValue: valueWithPeriod)

        // Then
        XCTAssertNil(localized)

        // When
        let unlocalized = localizer.unLocalized(shippingValue: localized)

        // Then
        XCTAssertNil(unlocalized)
    }

    func test_localizing_string_between_same_locales() {
        // Given
        let valueWithPeriod = "1.2"
        let localizer = DefaultShippingValueLocalizer(deviceLocale: usLocale, apiLocale: usLocale)

        // When
        let localized = localizer.localized(shippingValue: valueWithPeriod)

        // Then
        XCTAssertEqual(localized, "1.2")

        // When
        let unlocalized = localizer.unLocalized(shippingValue: localized)

        // Then
        XCTAssertEqual(unlocalized, "1.2")
    }

    func test_localizing_string_with_comma_as_thousand_separator() {
        // Given
        let valueWithCommaAsThousandSeparator = "1,000"
        let localizerWithSourceLocaleThatUsesDotAsDecimalSeparator = DefaultShippingValueLocalizer(deviceLocale: usLocale, apiLocale: usLocale)

        // When
        let localized = localizerWithSourceLocaleThatUsesDotAsDecimalSeparator.localized(shippingValue: valueWithCommaAsThousandSeparator)

        // Then

        // Should not localize string with thousand separators
        XCTAssertNil(localized)

        // When
        let unlocalized = localizerWithSourceLocaleThatUsesDotAsDecimalSeparator.unLocalized(shippingValue: localized)

        // Then
        XCTAssertNil(unlocalized)
    }

    func test_localizing_string_with_dot_as_thousand_separator() {
        // Given
        let valueWithDotAsThousandSeparator = "1.000"
        let localizerWithSourceLocaleThatUsesCommaAsDecimalSeparator = DefaultShippingValueLocalizer(deviceLocale: usLocale, apiLocale: itLocale)

        // When
        let localized = localizerWithSourceLocaleThatUsesCommaAsDecimalSeparator.localized(shippingValue: valueWithDotAsThousandSeparator)

        // Then

        // Should not localize string with thousand separators
        XCTAssertNil(localized)

        // When
        let unlocalized = localizerWithSourceLocaleThatUsesCommaAsDecimalSeparator.unLocalized(shippingValue: localized)

        // Then
        XCTAssertNil(unlocalized)
    }
}


import XCTest
import Combine
import WooFoundation
@testable import WooCommerce

final class PriceFieldFormatterTests: XCTestCase {

    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    func test_formatUserInput_prepends_currency_symbol() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("12")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$12")
    }

    func test_formatUserInput_formats_amount_with_custom_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .GBP,
                                              currencyPosition: .rightSpace,
                                              thousandSeparator: ",",
                                              decimalSeparator: ".",
                                              numberOfDecimals: 3)
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: customSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("12.203")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "12.203 £")
    }

    func test_formatUserInput_removes_non_digit_characters() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("hi:11.30-")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$11.30")
    }

    func test_formatUserInput_trims_more_than_two_decimal_numbers() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("$67.321432432")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$67.32")
    }

    func test_formatUserInput_removes_duplicated_decimal_separators() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("$6.7.3")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$6.7")
    }

    func test_formatUserInput_removes_consecutive_decimal_separators() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("$6...")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$6.")
    }

    func test_formatUserInput_changes_coma_separator_for_dot_separator_when_the_store_requires_it() {
        // Given
        let comaSeparatorLocale = Locale(identifier: "es_AR")
        let priceFieldFormatter = PriceFieldFormatter(locale: comaSeparatorLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("10,25")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$10.25")
    }

    func test_formatUserInput_uses_the_store_currency_symbol() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .EUR, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: customSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("10.25")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "€10.25")
    }

    func test_formatUserInput_placeholder_is_formatted_with_store_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .EUR, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ",", numberOfDecimals: 2)
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: customSettings)

        // When & Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "€0,00")
    }

    func test_formatUserInput_works_with_negative_numbers() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings, allowNegativeNumber: true)

        // When & Then
        _ = priceFieldFormatter.formatUserInput("-12")
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "-$12")

        // When & Then
        _ = priceFieldFormatter.formatUserInput("-hi:11.3030-")
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "-$11.30")
    }

    func test_formatUserInput_disallows_negative_numbers_by_default() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When & Then
        _ = priceFieldFormatter.formatUserInput("-12")
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$12")

        // When & Then
        _ = priceFieldFormatter.formatUserInput("-hi:11.3030-")
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$11.30")
    }

    func test_formatUserInput_when_decimals_more_than_expected_then_returns_the_max_numberOfDecimals_allowed() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .EUR,
                                              currencyPosition: .left,
                                              thousandSeparator: ".",
                                              decimalSeparator: ",",
                                              numberOfDecimals: 2)

        let priceFieldFormatter = PriceFieldFormatter(locale: Locale(identifier: "lt-LT"), storeCurrencySettings: customSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("1000,5123")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "€1000,51")
    }

    func test_formatUserInput_supports_numbers_with_decimal_and_thousands_separator() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("1,000.40")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$1000.40")
    }

    func test_formatUserInput_supports_numbers_with_decimal_and_thousands_separator_uses_custom_separators() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .EUR, currencyPosition: .left, thousandSeparator: ".", decimalSeparator: ",", numberOfDecimals: 2)
        let priceFieldFormatter = PriceFieldFormatter(locale: Locale(identifier: "lt-LT"), storeCurrencySettings: customSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("1000,5")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "€1000,5")
    }

    func test_formatUserInput_doesnt_support_numbers_with_decimal_and_thousands_separator_and_different_device_and_store_locale() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: Locale(identifier: "lt-LT"), storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("1,000.40")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$1.00")
    }

    func test_formatAmount_supports_numbers_with_decimal_and_thousands_separator_and_different_device_and_store_locale() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: Locale(identifier: "lt-LT"), storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatAmount(1000.4)

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$1000.40")
    }

    func test_formatAmount_works_with_negative_numbers() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings, allowNegativeNumber: true)

        // When
        _ = priceFieldFormatter.formatAmount(-12.00)

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "-$12.00")
    }

    func test_formatAmount_when_decimal_separator_has_spaces() {
        // Given store decimal separator has spaces
        let customSettings = CurrencySettings(currencyCode: .USD,
                                              currencyPosition: .left,
                                              thousandSeparator: ",",
                                              decimalSeparator: ".  ",
                                              numberOfDecimals: 2)

        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: customSettings)

        // When
        _ = priceFieldFormatter.formatUserInput("1000.5123")

        // Then formatting ignores spaces in store decimal separator settings
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$1000.51")
    }
}

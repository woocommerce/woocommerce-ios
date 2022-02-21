
import XCTest
import Combine

@testable import WooCommerce

final class PriceFieldFormatterTests: XCTestCase {


    private let usLocale = Locale(identifier: "en_US")
    private let usStoreSettings = CurrencySettings() // Default is US settings

    func test_view_model_prepends_currency_symbol() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatAmount("12")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$12")
    }

    func test_view_model_formats_amount_with_custom_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .GBP,
                                              currencyPosition: .rightSpace,
                                              thousandSeparator: ",",
                                              decimalSeparator: ".",
                                              numberOfDecimals: 3)
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: customSettings)

        // When
        _ = priceFieldFormatter.formatAmount("12.203")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "12.203 £")
    }

    func test_view_model_removes_non_digit_characters() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatAmount("hi:11.30-")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$11.30")
    }

    func test_view_model_trims_more_than_two_decimal_numbers() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatAmount("$67.321432432")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$67.32")
    }

    func test_view_model_removes_duplicated_decimal_separators() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatAmount("$6.7.3")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$6.7")
    }

    func test_view_model_removes_consecutive_decimal_separators() {
        // Given
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatAmount("$6...")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$6.")
    }

    func test_view_model_changes_coma_separator_for_dot_separator_when_the_store_requires_it() {
        // Given
        let comaSeparatorLocale = Locale(identifier: "es_AR")
        let priceFieldFormatter = PriceFieldFormatter(locale: comaSeparatorLocale, storeCurrencySettings: usStoreSettings)

        // When
        _ = priceFieldFormatter.formatAmount("10,25")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "$10.25")
    }

    func test_view_model_uses_the_store_currency_symbol() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .EUR, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: customSettings)

        // When
        _ = priceFieldFormatter.formatAmount("10.25")

        // Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "€10.25")
    }

    func test_amount_placeholder_is_formatted_with_store_currency_settings() {
        // Given
        let customSettings = CurrencySettings(currencyCode: .EUR, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ",", numberOfDecimals: 2)
        let priceFieldFormatter = PriceFieldFormatter(locale: usLocale, storeCurrencySettings: customSettings)

        // When & Then
        XCTAssertEqual(priceFieldFormatter.formattedAmount, "€0,00")
    }
}

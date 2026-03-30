import Foundation
import Testing
import WooFoundation

struct CurrencyInputSanitizerTests {

    // MARK: - sanitize Tests

    @Test func sanitize_when_valid_digits_only_then_returns_sanitized_text() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.sanitize("123")

        // Then
        #expect(result == "123")
    }

    @Test func sanitize_when_digits_with_decimal_then_returns_sanitized_text() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.sanitize("12.50")

        // Then
        #expect(result == "12.50")
    }

    @Test func sanitize_when_non_digit_characters_then_strips_them() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.sanitize("12abc")

        // Then
        #expect(result == "12")
    }

    @Test func sanitize_when_currency_symbols_then_strips_them() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.sanitize("$12.50")

        // Then
        #expect(result == "12.50")
    }

    @Test func sanitize_when_exceeds_fraction_digits_then_returns_nil() {
        // Given
        let sut = makeSUT(fractionDigits: 2)

        // When
        let result = sut.sanitize("12.501")

        // Then
        #expect(result == nil)
    }

    @Test func sanitize_when_multiple_decimal_separators_then_returns_nil() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.sanitize("12.50.1")

        // Then
        #expect(result == nil)
    }

    @Test func sanitize_when_empty_string_then_returns_empty() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.sanitize("")

        // Then
        #expect(result?.isEmpty == true)
    }

    @Test func sanitize_when_just_decimal_separator_then_allows_it() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.sanitize(".")

        // Then
        #expect(result == ".")
    }

    @Test func sanitize_when_device_comma_and_store_uses_period_then_converts() {
        // Given
        let sut = makeSUT(decimalSeparator: ".", deviceDecimalSeparator: ",")

        // When
        let result = sut.sanitize("12,50")

        // Then
        #expect(result == "12.50")
    }

    @Test func sanitize_when_store_uses_comma_then_accepts_comma() {
        // Given
        let sut = makeSUT(decimalSeparator: ",")

        // When
        let result = sut.sanitize("12,50")

        // Then
        #expect(result == "12,50")
    }

    @Test func sanitize_when_zero_fraction_digits_and_decimal_entered_then_returns_nil() {
        // Given
        let sut = makeSUT(fractionDigits: 0)

        // When
        let result = sut.sanitize("12.")

        // Then
        #expect(result == nil)
    }

    @Test func sanitize_when_three_fraction_digits_allowed_then_accepts_three() {
        // Given
        let sut = makeSUT(fractionDigits: 3)

        // When
        let result = sut.sanitize("12.345")

        // Then
        #expect(result == "12.345")
    }

    @Test func sanitize_when_three_fraction_digits_allowed_and_four_entered_then_returns_nil() {
        // Given
        let sut = makeSUT(fractionDigits: 3)

        // When
        let result = sut.sanitize("12.3456")

        // Then
        #expect(result == nil)
    }

    @Test func sanitize_when_whitespace_included_then_strips_it() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.sanitize("12 50")

        // Then
        #expect(result == "1250")
    }

    // MARK: - formatDecimal Tests

    @Test func formatDecimal_when_standard_amount_then_returns_formatted_string() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.formatDecimal(Decimal(string: "12.50")!)

        // Then
        #expect(result == "12.50")
    }

    @Test func formatDecimal_when_whole_number_then_includes_fraction_digits() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.formatDecimal(Decimal(10))

        // Then
        #expect(result == "10.00")
    }

    @Test func formatDecimal_when_store_uses_comma_separator_then_uses_comma() {
        // Given
        let sut = makeSUT(decimalSeparator: ",")

        // When
        let result = sut.formatDecimal(Decimal(string: "12.50")!)

        // Then
        #expect(result == "12,50")
    }

    @Test func formatDecimal_when_three_fraction_digits_then_formats_correctly() {
        // Given
        let sut = makeSUT(fractionDigits: 3)

        // When
        let result = sut.formatDecimal(Decimal(string: "12.5")!)

        // Then
        #expect(result == "12.500")
    }

    @Test func formatDecimal_when_zero_fraction_digits_then_formats_without_decimals() {
        // Given
        let sut = makeSUT(fractionDigits: 0)

        // When
        let result = sut.formatDecimal(Decimal(10))

        // Then
        #expect(result == "10")
    }

    @Test func formatDecimal_when_zero_then_returns_zero_with_fraction_digits() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.formatDecimal(Decimal(0))

        // Then
        #expect(result == "0.00")
    }

    @Test func formatDecimal_when_large_number_then_does_not_include_grouping_separator() {
        // Given
        let sut = makeSUT()

        // When
        let result = sut.formatDecimal(Decimal(string: "1234.56")!)

        // Then
        #expect(result == "1234.56")
    }

    // MARK: - addCurrencySymbol Tests

    @Test func addCurrencySymbol_when_left_position_then_prepends_symbol() {
        // Given
        let sut = makeSUT(currencyPosition: .left, currencyCode: .USD)

        // When
        let result = sut.addCurrencySymbol(to: "12.50")

        // Then
        #expect(result == "$12.50")
    }

    @Test func addCurrencySymbol_when_right_position_then_appends_symbol() {
        // Given
        let sut = makeSUT(currencyPosition: .right, currencyCode: .USD)

        // When
        let result = sut.addCurrencySymbol(to: "12.50")

        // Then
        #expect(result == "12.50$")
    }

    @Test func addCurrencySymbol_when_left_space_position_then_prepends_with_space() {
        // Given
        let sut = makeSUT(currencyPosition: .leftSpace, currencyCode: .USD)

        // When
        let result = sut.addCurrencySymbol(to: "12.50")

        // Then
        #expect(result == "$\u{00a0}12.50")
    }

    @Test func addCurrencySymbol_when_right_space_position_then_appends_with_space() {
        // Given
        let sut = makeSUT(currencyPosition: .rightSpace, currencyCode: .USD)

        // When
        let result = sut.addCurrencySymbol(to: "12.50")

        // Then
        #expect(result == "12.50\u{00a0}$")
    }

    @Test func addCurrencySymbol_when_negative_then_positions_minus_correctly() {
        // Given
        let sut = makeSUT(currencyPosition: .left, currencyCode: .USD)

        // When
        let result = sut.addCurrencySymbol(to: "-12.50", isNegative: true)

        // Then
        #expect(result == "-$12.50")
    }
}

// MARK: - Helpers

private extension CurrencyInputSanitizerTests {
    func makeSUT(
        currencyPosition: CurrencySettings.CurrencyPosition = .left,
        currencyCode: CurrencyCode = .USD,
        decimalSeparator: String = ".",
        fractionDigits: Int = 2,
        deviceDecimalSeparator: String = "."
    ) -> CurrencyInputSanitizer {
        let currencySettings = CurrencySettings(
            currencyCode: currencyCode,
            currencyPosition: currencyPosition,
            thousandSeparator: ",",
            decimalSeparator: decimalSeparator,
            numberOfDecimals: fractionDigits
        )
        return CurrencyInputSanitizer(
            currencySettings: currencySettings,
            deviceDecimalSeparator: deviceDecimalSeparator
        )
    }
}

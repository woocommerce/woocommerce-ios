import Foundation
import Testing
@testable import PointOfSale
import class WooFoundation.CurrencySettings
import enum WooFoundation.CurrencyCode

struct POSCashAmountInputFormatterTests {
    @Test func formattedAmount_when_currency_has_two_fraction_digits_then_shifts_digits() {
        // Given
        let sut = makeSUT(fractionDigits: 2)

        // When, Then
        #expect(sut.formattedAmount(from: "1") == "0.01")
        #expect(sut.formattedAmount(from: "12") == "0.12")
        #expect(sut.formattedAmount(from: "123") == "1.23")
        #expect(sut.formattedAmount(from: "1234") == "12.34")
    }

    @Test func formattedAmount_when_currency_has_no_fraction_digits_then_formats_whole_amount() {
        // Given
        let sut = makeSUT(currencyCode: .JPY, fractionDigits: 0)

        // When, Then
        #expect(sut.formattedAmount(from: "1") == "1")
        #expect(sut.formattedAmount(from: "12") == "12")
        #expect(sut.hasFractionDigits == false)
    }

    @Test func formattedAmount_when_amount_has_thousands_then_uses_store_grouping_separator() {
        // Given
        let sut = makeSUT(groupingSeparator: ",", fractionDigits: 2)

        // When
        let result = sut.formattedAmount(from: "123434434232333323")

        // Then
        #expect(result == "1,234,344,342,323,333.23")
    }

    @Test func formattedAmount_when_zero_decimal_amount_has_thousands_then_uses_store_grouping_separator() {
        // Given
        let sut = makeSUT(currencyCode: .JPY, groupingSeparator: ",", fractionDigits: 0)

        // When
        let result = sut.formattedAmount(from: "1234")

        // Then
        #expect(result == "1,234")
    }

    @Test func formattedAmount_when_currency_has_three_fraction_digits_then_shifts_three_places() {
        // Given
        let sut = makeSUT(fractionDigits: 3)

        // When, Then
        #expect(sut.formattedAmount(from: "1") == "0.001")
        #expect(sut.formattedAmount(from: "1234") == "1.234")
    }

    @Test func formattedAmount_when_store_uses_comma_separator_then_uses_store_separator() {
        // Given
        let sut = makeSUT(decimalSeparator: ",", groupingSeparator: ".", fractionDigits: 2)

        // When
        let result = sut.formattedAmount(from: "1234")

        // Then
        #expect(result == "12,34")
    }

    @Test func applyingEdit_when_first_digit_is_entered_over_preset_then_replaces_and_shifts_preset() {
        // Given
        let sut = makeSUT(fractionDigits: 2)

        // When
        let result = sut.applyingEdit(
            from: "1.00",
            to: "1.001",
            currentDigits: "100",
            isReplacingPreset: true
        )

        // Then
        #expect(result == "1")
        #expect(sut.formattedAmount(from: result ?? "") == "0.01")
    }

    @Test func applyingEdit_when_first_edit_deletes_from_preset_then_clears_preset() {
        // Given
        let sut = makeSUT(fractionDigits: 2)

        // When
        let result = sut.applyingEdit(
            from: "1.00",
            to: "1.0",
            currentDigits: "100",
            isReplacingPreset: true
        )

        // Then
        #expect(result?.isEmpty == true)
        #expect(sut.formattedAmount(from: result ?? "") == "0.00")
    }

    @Test func applyingEdit_when_digit_is_appended_then_adds_minor_unit_digit() {
        // Given
        let sut = makeSUT(fractionDigits: 2)

        // When
        let result = sut.applyingEdit(
            from: "0.01",
            to: "0.012",
            currentDigits: "1",
            isReplacingPreset: false
        )

        // Then
        #expect(result == "12")
        #expect(sut.formattedAmount(from: result ?? "") == "0.12")
    }

    @Test func applyingEdit_when_digit_is_deleted_then_removes_least_significant_digit() {
        // Given
        let sut = makeSUT(fractionDigits: 2)

        // When
        let result = sut.applyingEdit(
            from: "0.12",
            to: "0.1",
            currentDigits: "12",
            isReplacingPreset: false
        )

        // Then
        #expect(result == "1")
        #expect(sut.formattedAmount(from: result ?? "") == "0.01")
    }

    @Test func applyingEdit_when_decimal_separator_is_entered_then_ignores_edit() {
        // Given
        let sut = makeSUT(fractionDigits: 2)

        // When
        let result = sut.applyingEdit(
            from: "0.12",
            to: "0.12.",
            currentDigits: "12",
            isReplacingPreset: false
        )

        // Then
        #expect(result == nil)
    }

    @Test func applyingEdit_when_formatted_value_is_pasted_then_uses_only_digits() {
        // Given
        let sut = makeSUT(fractionDigits: 2)

        // When
        let result = sut.applyingEdit(
            from: "0.00",
            to: "$12.34",
            currentDigits: "",
            isReplacingPreset: false
        )

        // Then
        #expect(result == "1234")
        #expect(sut.formattedAmount(from: result ?? "") == "12.34")
    }
}

private extension POSCashAmountInputFormatterTests {
    func makeSUT(
        currencyCode: CurrencyCode = .USD,
        decimalSeparator: String = ".",
        groupingSeparator: String = ",",
        fractionDigits: Int
    ) -> POSCashAmountInputFormatter {
        POSCashAmountInputFormatter(currencySettings: CurrencySettings(
            currencyCode: currencyCode,
            currencyPosition: .left,
            thousandSeparator: groupingSeparator,
            decimalSeparator: decimalSeparator,
            numberOfDecimals: fractionDigits
        ))
    }
}

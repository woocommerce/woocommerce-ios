import Foundation
import Testing
@testable import PointOfSale
import class WooFoundation.CurrencySettings

struct CollectCashViewHelperTests {
    let sut = CollectCashViewHelper(currencySettings: CurrencySettings())

    @Test func updatechangeDueMessage_when_invalid_orderDecimal_then_returns_nil() {
        // Given
        let invalidOrderTotal = "not a value"
        let validAmountInput = "20.00"

        // When
        let result = sut.updatechangeDueMessage(
            orderTotal: invalidOrderTotal,
            textFieldAmountInput: validAmountInput)

        // Then
        #expect(result == nil)
    }

    @Test func updatechangeDueMessage_when_invalid_textFieldAmountInput_then_returns_nil() {
        // Given
        let invalidOrderTotal = "20.00"
        let validAmountInput = "not a value"

        // When
        let result = sut.updatechangeDueMessage(
            orderTotal: invalidOrderTotal,
            textFieldAmountInput: validAmountInput)

        // Then
        #expect(result == nil)
    }

    @Test func updatechangeDueMessage_when_input_is_below_total_then_returns_nil() {
        // Given
        let orderTotal = "20.00"
        let textFieldAmountInput = "10.00"

        // When
        let result = sut.updatechangeDueMessage(
            orderTotal: orderTotal,
            textFieldAmountInput: textFieldAmountInput)

        // Then
        #expect(result == nil)
    }

    @Test func updatechangeDueMessage_when_input_is_below_total_and_uses_grouping_separators_then_returns_nil() {
        // Given
        let orderTotal = "2,000.00"
        let textFieldAmountInput = "1,000.00"

        // When
        let result = sut.updatechangeDueMessage(
            orderTotal: orderTotal,
            textFieldAmountInput: textFieldAmountInput)

        // Then
        #expect(result == nil)
    }

    @Test func updatechangeDueMessage_when_input_is_above_total_then_returns_change_due_formatted_message() {
        // Given
        let orderTotal = "10.00"
        let textFieldAmountInput = "20.00"
        let expectedMessage = "Change due: $10.00"

        // When
        let result = sut.updatechangeDueMessage(
            orderTotal: orderTotal,
            textFieldAmountInput: textFieldAmountInput)

        // Then
        #expect(result == expectedMessage)
    }

    @Test func updatechangeDueMessage_when_input_equals_total_then_returns_nil() {
        // Given
        let orderTotal = "20.00"
        let textFieldAmountInput = "20.00"

        // When
        let result = sut.updatechangeDueMessage(
            orderTotal: orderTotal,
            textFieldAmountInput: textFieldAmountInput)

        // Then
        #expect(result == nil)
    }

    @Test func updateChangeDueMessage_when_input_has_both_dot_and_comma_grouping_separators_then_returns_formatted_change_due_correctly() {
        // Given
        let orderTotal = "$1,234.00"
        let inputAmount = "$1,235.00"
        let expectedMessage = "Change due: $1.00"

        // When
        let result = sut.updatechangeDueMessage(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount)

        // Then
        #expect(result == expectedMessage)
    }

    // MARK: - `isPaymentButtonEnabled` Tests

    @Test func isPaymentButtonEnabled_when_invalid_orderDecimal_then_returns_false() {
        // Given
        let invalidOrderTotal = "not a value"
        let validAmountInput = "20.00"
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: invalidOrderTotal,
            textFieldAmountInput: validAmountInput,
            isLoading: isLoading)

        // Then
        #expect(result == false)
    }

    @Test func isPaymentButtonEnabled_when_invalid_input_then_returns_false() {
        // Given
        let validOrderTotal = "20.00"
        let invalidAmountInput = "not a value"
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: validOrderTotal,
            textFieldAmountInput: invalidAmountInput,
            isLoading: isLoading)

        // Then
        #expect(result == false)
    }

    @Test func isPaymentButtonEnabled_when_inputDecimal_is_less_than_orderTotal_then_returns_false() {
        // Given
        let orderTotal = "20.00"
        let inputAmount = "10.00"
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount,
            isLoading: isLoading)

        // Then
        #expect(result == false)
    }

    @Test func isPaymentButtonEnabled_when_inputDecimal_is_equal_to_orderTotal_then_returns_true() {
        // Given
        let orderTotal = "20.00"
        let inputAmount = "20.00"
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount,
            isLoading: isLoading)

        // Then
        #expect(result == true)
    }

    @Test func isPaymentButtonEnabled_when_inputDecimal_is_equal_to_orderTotal_using_grouping_separators_then_returns_true() {
        // Given
        let orderTotal = "2,000.00"
        let inputAmount = "2,000.00"
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount,
            isLoading: isLoading)

        // Then
        #expect(result == true)
    }

    @Test func isPaymentButtonEnabled_when_input_has_both_dot_and_comma_grouping_separators_returns_false_when_input_amount_is_not_enough() {
        // Given
        let orderTotal = "$2,000.00"
        let inputAmount = "$1,235.00"
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount,
            isLoading: isLoading)

        // Then
        #expect(result == false)
    }

    @Test func isPaymentButtonEnabled_when_input_is_empty_and_orderTotal_is_zero_then_returns_true() {
        // Given
        let orderTotal = "$0.00"
        let inputAmount = ""
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount,
            isLoading: isLoading)

        // Then
        #expect(result == true)
    }

    @Test func isPaymentButtonEnabled_when_orderTotal_is_empty_then_returns_false() {
        // Given
        let orderTotal = ""
        let inputAmount = ""
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount,
            isLoading: isLoading)

        // Then
        #expect(result == false)
    }

    @Test func isPaymentButtonEnabled_when_inputDecimal_is_empty_and_less_than_orderTotal_then_returns_false() {
        // Given
        let orderTotal = "$1.00"
        let inputAmount = ""
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount,
            isLoading: isLoading)

        // Then
        #expect(result == false)
    }

    @Test func isPaymentButtonEnabled_when_isLoading_is_true_then_returns_false() {
        // Given
        let orderTotal = "$20.00"
        let inputAmount = "$20.00"
        let isLoading = true

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount,
            isLoading: isLoading)

        // Then
        #expect(result == false)
    }

    @Test func isPaymentButtonEnabled_when_input_is_greater_than_orderTotal_and_not_loading_then_returns_true() {
        // Given
        let orderTotal = "$10.00"
        let inputAmount = "$15.00"
        let isLoading = false

        // When
        let result = sut.isPaymentButtonEnabled(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount,
            isLoading: isLoading)

        // Then
        #expect(result == true)
    }

    // MARK: `formattedChangeDueAmount` Tests

    @Test func formattedChangeDueAmount_when_input_equals_total_and_includesZeroChange_is_true_then_returns_zero_amount() {
        // Given
        let orderTotal = "20.00"
        let textFieldAmountInput = "20.00"
        let expectedAmount = "0.00"

        // When
        let result = sut.formattedChangeDueAmount(
            orderTotal: orderTotal,
            textFieldAmountInput: textFieldAmountInput
        )

        // Then
        #expect(result == expectedAmount)
    }

    @Test func formattedChangeDueAmount_when_input_equals_total_with_grouping_separators_and_includesZeroChange_is_true_then_returns_zero_amount() {
        // Given
        let orderTotal = "2,000.00"
        let textFieldAmountInput = "2,000.00"
        let expectedAmount = "0.00"

        // When
        let result = sut.formattedChangeDueAmount(
            orderTotal: orderTotal,
            textFieldAmountInput: textFieldAmountInput
        )

        // Then
        #expect(result == expectedAmount)
    }

    @Test func formattedChangeDueAmount_when_input_is_above_total_then_returns_change_due_formatted_amount() {
        // Given
        let orderTotal = "50.50"
        let textFieldAmountInput = "2,000.00"
        let expectedAmount = "1,949.50"

        // When
        let result = sut.formattedChangeDueAmount(
            orderTotal: orderTotal,
            textFieldAmountInput: textFieldAmountInput
        )

        // Then
        #expect(result == expectedAmount)
    }

    // MARK: - `parseCurrency` Tests

    @Test func parseCurrency_when_valid_decimal_string_then_returns_decimal() {
        // Given
        let amountString = "123.45"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "123.45"))
    }

    @Test func parseCurrency_when_string_with_currency_symbol_then_returns_decimal() {
        // Given
        let amountString = "$123.45"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "123.45"))
    }

    @Test func parseCurrency_when_string_with_grouping_separator_then_returns_decimal() {
        // Given
        let amountString = "1,234.56"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "1234.56"))
    }

    @Test func parseCurrency_when_string_with_currency_symbol_and_grouping_separator_then_returns_decimal() {
        // Given
        let amountString = "$1,234.56"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "1234.56"))
    }

    @Test func parseCurrency_when_string_with_leading_and_trailing_whitespace_then_returns_decimal() {
        // Given
        let amountString = "  123.45  "

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "123.45"))
    }

    @Test func parseCurrency_when_zero_amount_then_returns_zero_decimal() {
        // Given
        let amountString = "0.00"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "0"))
    }

    @Test func parseCurrency_when_zero_with_currency_symbol_then_returns_zero_decimal() {
        // Given
        let amountString = "$0.00"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "0"))
    }

    @Test func parseCurrency_when_large_amount_with_multiple_grouping_separators_then_returns_decimal() {
        // Given
        let amountString = "1,234,567.89"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "1234567.89"))
    }

    @Test func parseCurrency_when_invalid_string_then_returns_nil() {
        // Given
        let amountString = "not a number"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == nil)
    }

    @Test func parseCurrency_when_empty_string_then_returns_nil() {
        // Given
        let amountString = ""

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == nil)
    }

    @Test func parseCurrency_when_only_currency_symbol_then_returns_nil() {
        // Given
        let amountString = "$"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == nil)
    }

    @Test func parseCurrency_when_only_whitespace_then_returns_nil() {
        // Given
        let amountString = "   "

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == nil)
    }

    @Test func parseCurrency_when_string_with_letters_and_numbers_then_returns_nil() {
        // Given
        let amountString = "abc123.45"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == nil)
    }

    @Test func parseCurrency_when_multiple_decimal_points_then_returns_nil() {
        // Given
        let amountString = "123.45.67"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == nil)
    }

    @Test func parseCurrency_when_integer_without_decimal_then_returns_decimal() {
        // Given
        let amountString = "123"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "123"))
    }

    @Test func parseCurrency_when_integer_with_currency_symbol_then_returns_decimal() {
        // Given
        let amountString = "$123"

        // When
        let result = sut.parseCurrency(amountString)

        // Then
        #expect(result == Decimal(string: "123"))
    }
}

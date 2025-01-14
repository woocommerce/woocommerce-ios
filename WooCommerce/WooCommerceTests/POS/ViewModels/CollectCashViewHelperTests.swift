import Testing
@testable import WooCommerce

struct CollectCashViewHelperTests {
    let sut = CollectCashViewHelper()

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

    @Test func validateAmountOnSubmit_when_invalid_orderDecimal_then_returns_false_with_expected_error_message() {
        // Given
        let invalidOrderTotal = "not a value"
        let validAmountInput = "20.00"
        let expectedErrorMessage = "Error trying to process payment. Try again."
        var capturedErrorMessage: String?

        // When
        let result = sut.validateAmountOnSubmit(
            orderTotal: invalidOrderTotal,
            textFieldAmountInput: validAmountInput,
            onError: { error in
                capturedErrorMessage = error
            })

        // Then
        #expect(result == false)
        #expect(capturedErrorMessage == expectedErrorMessage)
    }

    @Test func validateAmountOnSubmit_when_invalid_input_then_returns_false_with_expected_error_message() {
        // Given
        let validOrderTotal = "20.00"
        let invalidAmountInput = "not a value"
        let expectedErrorMessage = "Error trying to process payment. Try again."
        var capturedErrorMessage: String?

        // When
        let result = sut.validateAmountOnSubmit(
            orderTotal: validOrderTotal,
            textFieldAmountInput: invalidAmountInput,
            onError: { error in
                capturedErrorMessage = error
            })

        // Then
        #expect(result == false)
        #expect(capturedErrorMessage == expectedErrorMessage)
    }

    @Test func validateAmountOnSubmit_when_inputDecimal_is_less_than_orderTotal_then_returns_false_with_expected_error_message() {
        // Given
        let orderTotal = "20.00"
        let inputAmount = "10.00"
        let expectedErrorMessage = "Amount must be more or equal to total."
        var capturedErrorMessage: String?

        // When
        let result = sut.validateAmountOnSubmit(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount
        ) { error in
            capturedErrorMessage = error
        }

        // Then
        #expect(result == false)
        #expect(capturedErrorMessage == expectedErrorMessage)
    }

    @Test func validateAmountOnSubmit_when_inputDecimal_is_greater_than_or_equal_to_orderTotal_then_returns_true() {
        // Given
        let orderTotal = "20.00"
        let inputAmount = "20.00"
        var capturedErrorMessage: String?

        // When
        let result = sut.validateAmountOnSubmit(
            orderTotal: orderTotal,
            textFieldAmountInput: inputAmount
        ) { error in
            capturedErrorMessage = error
        }

        // Then
        #expect(result == true)
        #expect(capturedErrorMessage == nil)
    }
}

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
}

import Foundation
import Testing
@testable import PointOfSale

@MainActor
struct POSCashSessionEntryValidationTests {
    @Test func test_payOut_when_amount_exceeds_expected_cash_then_cannot_continue() {
        // Given
        let amount = Decimal(101)

        // When
        let canContinue = POSCashSessionEntryView.isValidAmount(amount, action: .payOut,
                                                                 hasEditedAmount: true, expectedCash: 100)

        // Then
        #expect(!canContinue)
        #expect(POSCashSessionEntryView.exceedsAvailableCash(amount, action: .payOut, expectedCash: 100))
    }

    @Test func test_payOut_when_amount_equals_expected_cash_then_can_continue() {
        // Given
        let amount = Decimal(100)

        // When
        let canContinue = POSCashSessionEntryView.isValidAmount(amount, action: .payOut,
                                                                 hasEditedAmount: true, expectedCash: 100)

        // Then
        #expect(canContinue)
        #expect(!POSCashSessionEntryView.exceedsAvailableCash(amount, action: .payOut, expectedCash: 100))
    }

    @Test func test_payOut_when_session_is_unavailable_then_cannot_continue() {
        // Given
        let amount = Decimal(10)

        // When
        let canContinue = POSCashSessionEntryView.isValidAmount(amount, action: .payOut,
                                                                 hasEditedAmount: true, expectedCash: nil)

        // Then
        #expect(!canContinue)
    }

    @Test func test_payIn_when_amount_exceeds_expected_cash_then_can_continue() {
        // Given
        let amount = Decimal(101)

        // When
        let canContinue = POSCashSessionEntryView.isValidAmount(amount, action: .payIn,
                                                                 hasEditedAmount: true, expectedCash: 100)

        // Then
        #expect(canContinue)
    }
}

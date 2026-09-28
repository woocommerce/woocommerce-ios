import Testing
@testable import PointOfSale

struct PointOfSalePaymentSuccessViewModelTests {
    @Test
    func test_cash_success_when_change_is_due_then_shows_change() {
        // Given
        let changeDue = "Change due: $5.00"

        // When
        let sut = PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$10.00",
                                                     paymentMethod: .cash,
                                                     changeDueMessage: changeDue)

        // Then
        #expect(sut.changeDueMessage == changeDue)
    }

    @Test
    func test_cash_success_when_change_is_zero_then_omits_change() {
        // When
        let sut = PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$10.00", paymentMethod: .cash)

        // Then
        #expect(sut.changeDueMessage == nil)
    }

    @Test
    func test_card_success_then_omits_cash_change() {
        // When
        let sut = PointOfSalePaymentSuccessViewModel(formattedOrderTotal: "$10.00",
                                                     paymentMethod: .card,
                                                     changeDueMessage: "Change due: $5.00")

        // Then
        #expect(sut.changeDueMessage == nil)
    }
}

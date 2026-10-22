import Foundation
import Testing
import struct Yosemite.Order
import enum Yosemite.OrderStatusEnum
@testable import PointOfSale

@MainActor
struct POSCartScanToPayVerifierTests {
    @Test
    func test_classify_when_on_hold_without_paid_date_then_payment_is_pending() {
        // Given
        let order = Order.fake().copy(status: .onHold, datePaid: .some(nil))

        // When
        let result = POSCartScanToPayVerifier.classify(order: order)

        // Then
        #expect(result == .pending)
    }

    @Test
    func test_classify_when_on_hold_with_paid_date_then_payment_is_paid() {
        // Given
        let order = Order.fake().copy(status: .onHold, datePaid: Date(timeIntervalSince1970: 1))

        // When
        let result = POSCartScanToPayVerifier.classify(order: order)

        // Then
        #expect(result == .paid(order))
    }

    @Test(arguments: [OrderStatusEnum.processing, .completed])
    func test_classify_when_paid_status_without_paid_date_then_payment_is_paid(status: OrderStatusEnum) {
        // Given
        let order = Order.fake().copy(status: status, datePaid: .some(nil))

        // When
        let result = POSCartScanToPayVerifier.classify(order: order)

        // Then
        #expect(result == .paid(order))
    }

    @Test(arguments: [OrderStatusEnum.autoDraft, .pending, .cancelled, .refunded, .failed, .custom("awaiting-transfer")])
    func test_classify_when_unpaid_status_without_paid_date_then_payment_is_pending(status: OrderStatusEnum) {
        // Given
        let order = Order.fake().copy(status: status, datePaid: .some(nil))

        // When
        let result = POSCartScanToPayVerifier.classify(order: order)

        // Then
        #expect(result == .pending)
    }
}

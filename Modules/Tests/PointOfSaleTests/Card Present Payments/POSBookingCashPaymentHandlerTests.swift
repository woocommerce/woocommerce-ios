import Testing
import Foundation
import struct Yosemite.Order
@testable import PointOfSale

struct POSBookingCashPaymentHandlerTests {

    @Test("completeCashPayment calls markOrderAsCompleted on the order service")
    func completeCashPayment_callsMarkOrderAsCompleted() async throws {
        let orderService = MockPOSOrderService()
        let order = Order.fake().copy(orderID: 100)

        let sut = POSBookingCashPaymentHandler(orderService: orderService)

        try await sut.completeCashPayment(for: order, changeDueAmount: "$5.00")

        #expect(orderService.spyCashPaymentChangeDueAmount == "$5.00")
    }

    @Test("completeCashPayment passes nil change due when none provided")
    func completeCashPayment_passesNilChangeDue() async throws {
        let orderService = MockPOSOrderService()
        let order = Order.fake()

        let sut = POSBookingCashPaymentHandler(orderService: orderService)

        try await sut.completeCashPayment(for: order, changeDueAmount: nil)

        #expect(orderService.spyCashPaymentChangeDueAmount == nil)
    }

    @Test("completeCashPayment throws when order service fails")
    func completeCashPayment_throwsWhenServiceFails() async {
        let orderService = MockPOSOrderService()
        orderService.resultToReturn = .failure(NSError(domain: "test", code: 1))
        let order = Order.fake()

        let sut = POSBookingCashPaymentHandler(orderService: orderService)

        await #expect(throws: Error.self) {
            try await sut.completeCashPayment(for: order, changeDueAmount: nil)
        }
    }
}

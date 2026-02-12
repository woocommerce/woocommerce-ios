import Testing
import Foundation
import struct Yosemite.Order
@testable import PointOfSale

struct POSBookingPaymentOrderProviderTests {

    @Test("provideOrder loads order by ID from order service")
    func provideOrder_loadsOrderByID() async throws {
        let orderService = MockPOSOrderService()
        let expectedOrder = Order.fake().copy(orderID: 42, total: "25.00")
        orderService.orderToReturn = expectedOrder

        let sut = POSBookingPaymentOrderProvider(
            orderID: 42,
            formattedTotal: "$25.00",
            orderService: orderService)

        let result = try await sut.provideOrder()

        #expect(orderService.loadOrderWasCalled == true)
        #expect(result.order.orderID == 42)
        #expect(result.formattedTotal == "$25.00")
        #expect(result.totalDecimal == 25.00)
    }

    @Test("provideOrder parses total decimal from order")
    func provideOrder_parsesTotalDecimalFromOrder() async throws {
        let orderService = MockPOSOrderService()
        orderService.orderToReturn = Order.fake().copy(total: "99.95")

        let sut = POSBookingPaymentOrderProvider(
            orderID: 1,
            formattedTotal: "$99.95",
            orderService: orderService)

        let result = try await sut.provideOrder()

        #expect(result.totalDecimal == Decimal(string: "99.95"))
    }

    @Test("provideOrder defaults to zero when order total is not parseable")
    func provideOrder_defaultsToZero_whenTotalNotParseable() async throws {
        let orderService = MockPOSOrderService()
        orderService.orderToReturn = Order.fake().copy(total: "invalid")

        let sut = POSBookingPaymentOrderProvider(
            orderID: 1,
            formattedTotal: "$0.00",
            orderService: orderService)

        let result = try await sut.provideOrder()

        #expect(result.totalDecimal == 0)
    }

    @Test("provideOrder throws when order service fails")
    func provideOrder_throwsWhenServiceFails() async {
        let orderService = MockPOSOrderService()
        orderService.errorToReturn = NSError(domain: "test", code: 1)

        let sut = POSBookingPaymentOrderProvider(
            orderID: 1,
            formattedTotal: "$10.00",
            orderService: orderService)

        await #expect(throws: Error.self) {
            try await sut.provideOrder()
        }
    }
}

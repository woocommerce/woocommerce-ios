// POSBookingPaymentControllerTests.swift
import Testing
import Foundation
import Combine
import Fakes
@testable import PointOfSale
@testable import Yosemite

@MainActor
struct POSBookingPaymentControllerTests {
    private let bookingService = MockPOSBookingService()
    private let cardPaymentFacade = MockCardPresentPaymentService()
    private let orderProvider = MockOrderProvider()

    private func makeSUT(booking: POSBooking? = nil) -> POSBookingPaymentController {
        let testBooking = booking ?? POSBookingTestHelpers.makeBooking()
        return POSBookingPaymentController(
            siteID: 123,
            booking: testBooking,
            bookingService: bookingService,
            cardPaymentFacade: cardPaymentFacade,
            orderProvider: orderProvider
        )
    }

    @Test func initial_state_is_ready() {
        let sut = makeSUT()
        #expect(sut.paymentState == .ready)
    }

    @Test func collectCardPayment_success_marks_booking_as_paid() async throws {
        let booking = POSBookingTestHelpers.makeBooking(bookingID: 42)
        let sut = makeSUT(booking: booking)

        try await sut.collectCardPayment()

        #expect(bookingService.markBookingAsPaidCallCount == 1)
        #expect(bookingService.markBookingAsPaidBookingID == 42)
    }

    @Test func collectCardPayment_success_transitions_to_success_state() async throws {
        let sut = makeSUT()

        try await sut.collectCardPayment()

        #expect(sut.paymentState == .success)
    }

    @Test func cancelPayment_calls_facade_cancel() async throws {
        let sut = makeSUT()

        try await sut.cancelPayment()

        #expect(cardPaymentFacade.cancelPaymentCalled == true)
    }

    @Test func reset_returns_to_ready_state() async throws {
        let sut = makeSUT()
        try await sut.collectCardPayment()

        sut.reset()

        #expect(sut.paymentState == .ready)
    }
}

// MARK: - Mock Order Provider

final class MockOrderProvider: POSOrderProviding {
    var orderToReturn: Order = Order.fake()
    var shouldThrow = false

    func fetchOrder(siteID: Int64, orderID: Int64) async throws -> Order {
        if shouldThrow {
            throw NSError(domain: "test", code: 1)
        }
        return orderToReturn.copy(siteID: siteID, orderID: orderID)
    }
}

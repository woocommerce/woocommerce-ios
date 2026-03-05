import Testing
import Foundation
@testable import PointOfSale
import struct Yosemite.POSBooking
import struct Yosemite.POSOrder
import enum Yosemite.BookingStatus
import enum Yosemite.BookingAttendanceStatus
import enum Yosemite.OrderStatusEnum

@MainActor
struct POSBookingsModelTests {

    // MARK: - updateAfterSuccessfulPayment

    @Test func test_updateAfterSuccessfulPayment_then_calls_updateBookingOptimistically_with_bookingID() async {
        // Given
        let (sut, bookingsController, _) = makeSUT()

        // When
        await sut.updateAfterSuccessfulPayment(bookingID: 42)

        // Then
        #expect(bookingsController.updateBookingOptimisticallyCalledWith == 42)
    }

    @Test func test_updateAfterSuccessfulPayment_then_sets_status_to_paid() async {
        // Given
        let (sut, bookingsController, _) = makeSUT()
        let booking = makeBooking(id: 1, status: .confirmed)
        bookingsController.bookingForOptimisticUpdate = booking

        // When
        await sut.updateAfterSuccessfulPayment(bookingID: 1)

        // Then
        #expect(bookingsController.optimisticUpdateResult?.status == .paid)
    }

    @Test func test_updateAfterSuccessfulPayment_then_sets_datePaid() async {
        // Given
        let (sut, bookingsController, _) = makeSUT()
        let booking = makeBooking(id: 1, order: makeOrder(id: 10, datePaid: nil))
        bookingsController.bookingForOptimisticUpdate = booking

        // When
        await sut.updateAfterSuccessfulPayment(bookingID: 1)

        // Then
        #expect(bookingsController.optimisticUpdateResult?.order.datePaid != nil)
    }

    @Test func test_updateAfterSuccessfulPayment_then_preserves_other_booking_fields() async {
        // Given
        let (sut, bookingsController, _) = makeSUT()
        let booking = makeBooking(id: 5, status: .confirmed)
        bookingsController.bookingForOptimisticUpdate = booking

        // When
        await sut.updateAfterSuccessfulPayment(bookingID: 5)

        // Then
        let result = bookingsController.optimisticUpdateResult
        #expect(result?.id == 5)
        #expect(result?.serviceName == booking.serviceName)
    }

    // MARK: - updateAfterRefund

    @Test func test_updateAfterRefund_then_calls_updateBookingOptimistically_with_bookingID() async {
        // Given
        let (sut, bookingsController, _) = makeSUT()

        // When
        await sut.updateAfterRefund(bookingID: 77)

        // Then
        #expect(bookingsController.updateBookingOptimisticallyCalledWith == 77)
    }

    @Test func test_updateAfterRefund_then_sets_order_status_to_refunded() async {
        // Given
        let (sut, bookingsController, _) = makeSUT()
        let booking = makeBooking(id: 1, order: makeOrder(id: 10, status: .completed))
        bookingsController.bookingForOptimisticUpdate = booking

        // When
        await sut.updateAfterRefund(bookingID: 1)

        // Then
        #expect(bookingsController.optimisticUpdateResult?.order.status == .refunded)
    }

    @Test func test_updateAfterRefund_then_preserves_booking_status() async {
        // Given
        let (sut, bookingsController, _) = makeSUT()
        let booking = makeBooking(id: 1, status: .paid)
        bookingsController.bookingForOptimisticUpdate = booking

        // When
        await sut.updateAfterRefund(bookingID: 1)

        // Then
        #expect(bookingsController.optimisticUpdateResult?.status == .paid)
    }
}

// MARK: - Helpers

private extension POSBookingsModelTests {
    func makeSUT() -> (POSBookingsModel, MockPOSBookingListController, MockCardPresentPaymentService) {
        let bookingsController = MockPOSBookingListController()
        let cardPresentPaymentService = MockCardPresentPaymentService()
        let orderService = MockPOSOrderService()
        let receiptSender = MockPOSReceiptSender()
        let analyticsTracker = MockPOSCollectOrderPaymentAnalyticsTracker()

        let sut = POSBookingsModel(
            bookingsController: bookingsController,
            cardPresentPaymentService: cardPresentPaymentService,
            orderService: orderService,
            receiptSender: receiptSender,
            collectOrderPaymentAnalyticsTracker: analyticsTracker
        )
        return (sut, bookingsController, cardPresentPaymentService)
    }

    func makeBooking(id: Int64,
                     customerID: Int64 = 0,
                     status: BookingStatus = .confirmed,
                     orderID: Int64? = 10,
                     order: POSOrder? = nil) -> POSBooking {
        POSBooking(
            id: id,
            customerID: customerID,
            customerName: "Customer \(id)",
            serviceName: "Service \(id)",
            startDate: Date(),
            endDate: Date().addingTimeInterval(3600),
            formattedAmount: "$50.00",
            status: status,
            attendanceStatus: .unattended,
            orderID: orderID,
            resourceName: nil,
            order: order ?? makeOrder(id: orderID ?? 0)
        )
    }

    func makeOrder(id: Int64,
                   status: OrderStatusEnum = .completed,
                   datePaid: Date? = Date()) -> POSOrder {
        POSOrder(
            id: id,
            number: "\(id)",
            dateCreated: Date(),
            status: status,
            formattedTotal: "$50.00",
            formattedSubtotal: "$50.00",
            paymentMethodID: "cod",
            paymentMethodTitle: "Cash",
            formattedDiscountTotal: nil,
            formattedTotalTax: "$0.00",
            formattedPaymentTotal: "$50.00",
            datePaid: datePaid
        )
    }
}

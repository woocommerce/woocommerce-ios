import XCTest
import TestKit
import Yosemite
import Fakes

@testable import WooCommerce

@MainActor
final class BookingDetailsViewModelTests: XCTestCase {
    private var storesManager: MockStoresManager!
    private var storageManager: MockStorageManager!
    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: .makeForTesting())
        storageManager = MockStorageManager()
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
    }

    override func tearDown() {
        super.tearDown()
        storesManager = nil
        storageManager = nil
        analytics = nil
        analyticsProvider = nil
    }

    func test_setupSections_populates_all_sections_with_complete_booking() {
        // Given
        let billingAddress = Address.fake().copy(
            firstName: "John",
            lastName: "Doe",
            address1: "123 Fake St",
            address2: "Apt 4B",
            city: "Faketown",
            state: "FS",
            postcode: "12345",
            country: "FK",
            phone: "123-456-7890",
            email: "john.doe@example.com"
        )

        let customerInfo = BookingCustomerInfo(billingAddress: billingAddress)
        let productInfo = BookingProductInfo(name: "Women's Haircut")
        let paymentInfo = BookingPaymentInfo(
            paymentMethodID: "credit-card",
            paymentMethodTitle: "Visa",
            subtotal: "50",
            subtotalTax: "0",
            total: "50",
            totalTax: "0"
        )
        let orderInfo = BookingOrderInfo(
            statusKey: "confirmed",
            paymentInfo: paymentInfo,
            customerInfo: customerInfo,
            productInfo: productInfo
        )

        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        XCTAssertEqual(viewModel.sections.count, 6)

        // Verify section order
        if case .header = viewModel.sections[0].content {
            // Header section exists
        } else {
            XCTFail("Expected header section at index 0")
        }

        if case .appointmentDetails = viewModel.sections[1].content {
            // Appointment details section exists
        } else {
            XCTFail("Expected appointment details section at index 1")
        }

        if case .customer = viewModel.sections[2].content {
            // Customer section exists
        } else {
            XCTFail("Expected customer section at index 2")
        }

        if case .attendance = viewModel.sections[3].content {
            // Attendance section exists
        } else {
            XCTFail("Expected attendance section at index 3")
        }

        if case .payment = viewModel.sections[4].content {
            // Payment section exists
        } else {
            XCTFail("Expected payment section at index 4")
        }

        if case .bookingNotes = viewModel.sections[5].content {
            // Booking notes section exists
        } else {
            XCTFail("Expected booking notes section at index 5")
        }
    }

    func test_setupSections_excludes_customer_section_when_billing_address_is_missing() {
        // Given
        let orderInfo = BookingOrderInfo(
            statusKey: "confirmed",
            paymentInfo: nil,
            customerInfo: nil,
            productInfo: nil
        )
        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        XCTAssertEqual(viewModel.sections.count, 5)

        // Verify customer section is not present
        let hasCustomerSection = viewModel.sections.contains { section in
            if case .customer = section.content {
                return true
            }
            return false
        }
        XCTAssertFalse(hasCustomerSection)
    }

    func test_header_content_uses_correct_contents() {
        // Given
        let billingAddress = Address.fake().copy(
            firstName: "Jane",
            lastName: "Smith"
        )
        let customerInfo = BookingCustomerInfo(billingAddress: billingAddress)
        let productInfo = BookingProductInfo(name: "Massage Therapy")
        let orderInfo = BookingOrderInfo(
            statusKey: "confirmed",
            paymentInfo: nil,
            customerInfo: customerInfo,
            productInfo: productInfo
        )
        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        let headerSection = viewModel.sections.first { section in
            if case .header = section.content {
                return true
            }
            return false
        }

        guard let headerSection = headerSection,
              case let .header(headerContent) = headerSection.content else {
            XCTFail("Header section not found")
            return
        }

        XCTAssertEqual(headerContent.serviceLine, "Massage Therapy")
        XCTAssertEqual(headerContent.customerLine, "Jane Smith")
    }

    func test_customer_content_populated_from_billing_address() {
        // Given
        let billingAddress = Address.fake().copy(
            firstName: "Alice",
            lastName: "Johnson",
            address1: "456 Main St",
            address2: "Suite 100",
            city: "Springfield",
            state: "IL",
            postcode: "62701",
            country: "US",
            phone: "555-1234",
            email: "alice@example.com"
        )
        let customerInfo = BookingCustomerInfo(billingAddress: billingAddress)
        let orderInfo = BookingOrderInfo(
            statusKey: "confirmed",
            paymentInfo: nil,
            customerInfo: customerInfo,
            productInfo: nil
        )
        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        let customerSection = viewModel.sections.first { section in
            if case .customer = section.content {
                return true
            }
            return false
        }

        guard let customerSection = customerSection,
              case let .customer(customerContent) = customerSection.content else {
            XCTFail("Customer section not found")
            return
        }

        XCTAssertEqual(customerContent.nameText, "Alice Johnson")
        XCTAssertEqual(customerContent.emailText, "alice@example.com")
        XCTAssertEqual(customerContent.phoneText, "555-1234")

        let expectedAddress = "456 Main St\nSuite 100\nSpringfield\nIL\n62701\nUS"
        XCTAssertEqual(customerContent.billingAddressText, expectedAddress)
    }

    func test_customer_content_includes_customer_note() {
        // Given
        let billingAddress = Address.fake().copy(
            firstName: "Alice",
            lastName: "Johnson",
            address1: "456 Main St",
            city: "Springfield",
            state: "IL",
            postcode: "62701",
            country: "US"
        )
        let note = "Please ring the bell twice"
        let customerInfo = BookingCustomerInfo(billingAddress: billingAddress, note: note)
        let orderInfo = BookingOrderInfo(
            statusKey: "confirmed",
            paymentInfo: nil,
            customerInfo: customerInfo,
            productInfo: nil
        )
        let booking = Booking.fake().copy(orderInfo: orderInfo)

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        let customerSection = viewModel.sections.first { section in
            if case .customer = section.content {
                return true
            }
            return false
        }

        guard let customerSection = customerSection,
              case let .customer(customerContent) = customerSection.content else {
            XCTFail("Customer section not found")
            return
        }

        XCTAssertEqual(customerContent.noteText, note)
    }

    func test_navigation_title_includes_booking_id() {
        // Given
        let booking = Booking.fake().copy(bookingID: 12345)

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        XCTAssertTrue(viewModel.navigationTitle.contains("12345"))
    }

    func test_updateAttendanceStatus_whenNewStatusIsProvided_dispatchesUpdateBookingAttendanceStatusAction() throws {
        // Given
        let booking = Booking.fake()
        let viewModel = givenViewModel(booking: booking)
        let newStatus = BookingAttendanceStatus.attended

        // When
        viewModel.updateAttendanceStatus(to: newStatus)

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        guard let action = storesManager.receivedActions.first as? BookingAction else {
            XCTFail("Incorrect action type dispatched")
            return
        }

        guard case let .updateBookingAttendanceStatus(siteID, bookingID, status, _) = action else {
            XCTFail("Incorrect action case dispatched")
            return
        }

        XCTAssertEqual(siteID, booking.siteID)
        XCTAssertEqual(bookingID, booking.bookingID)
        XCTAssertEqual(status, newStatus)

        analyticsProvider.assertReceived(event: "booking_detail_attendance_status_updated",
                                         with: ["booking_status": "attended"])
    }

    func test_error_notice_displayed_when_attendance_staus_update_fails() {
        // Given
        let booking = Booking.fake()
        let viewModel = givenViewModel(booking: booking)
        let newStatus = BookingAttendanceStatus.attended
        enum TestError: Error { case generic }

        // When
        viewModel.updateAttendanceStatus(to: newStatus)

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        guard let action = storesManager.receivedActions.first as? BookingAction else {
            XCTFail("Incorrect action type dispatched")
            return
        }

        guard case let .updateBookingAttendanceStatus(_, _, _, onCompletion) = action else {
            XCTFail("Incorrect action case dispatched")
            return
        }

        onCompletion(TestError.generic)

        XCTAssertNotNil(viewModel.notice)
        XCTAssertEqual(viewModel.notice?.feedbackType, .error)

        let messageFormat = NSLocalizedString(
            "BookingDetailsView.attendanceStatus.failureMessage",
            value: "Unable to change attendance status of Booking #%1$d.",
            comment: ""
        )
        let expectedMessage = String(format: messageFormat, booking.bookingID)
        XCTAssertEqual(viewModel.notice?.message, expectedMessage)
    }

    func test_init_whenBookingHasStatusAndAttendanceStatus_updatesHeaderContentWithCorrectLocalizedStrings() {
        // Given
        let booking = Booking.fake().copy(
            statusKey: "paid",
            attendanceStatusKey: "attended"
        )

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        let headerSection = viewModel.sections.first { section in
            if case .header = section.content {
                return true
            }
            return false
        }

        guard let headerSection = headerSection,
              case let .header(headerContent) = headerSection.content else {
            XCTFail("Header section not found")
            return
        }
        XCTAssertEqual(headerContent.statusBadge.text, "Attended")
    }

    func test_init_whenBookingHasAttendanceStatus_updatesAttendanceContentWithCorrectLocalizedString() {
        // Given
        let booking = Booking.fake().copy(
            attendanceStatusKey: "unattended"
        )

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        let attendanceSection = viewModel.sections.first { section in
            if case .attendance = section.content {
                return true
            }
            return false
        }

        guard let attendanceSection = attendanceSection,
              case let .attendance(attendanceContent) = attendanceSection.content else {
            XCTFail("Attendance section not found")
            return
        }

        XCTAssertEqual(attendanceContent.value, "Unattended")
    }

    func test_attendance_section_is_hidden_when_booking_is_cancelled() {
        // Given
        let booking = Booking.fake().copy(
            statusKey: "cancelled",
            attendanceStatusKey: "unattended"
        )

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        let containsAttendanceSection = viewModel.sections.contains { section in
            if case .attendance = section.content {
                return true
            }
            return false
        }

        XCTAssertFalse(containsAttendanceSection)
    }

    func test_view_order_is_hidden_when_booking_order_id_is_invalid() {
        // Given
        let booking = Booking.fake().copy(
            orderID: 0
        )

        // When
        let viewModel = givenViewModel(booking: booking)

        // Then
        let paymentSection = viewModel.sections.first { section in
            if case .payment = section.content {
                return true
            }
            return false
        }

        guard let paymentSection = paymentSection,
              case let .payment(paymentContent) = paymentSection.content else {
            XCTFail("Payment section not found")
            return
        }

        XCTAssertFalse(viewModel.isViewOrderAvailable)
        XCTAssertFalse(paymentContent.actions.contains(.viewOrder))
    }

    func test_event_fired_when_booking_marked_as_paid() async throws {
        // Given
        let viewModel = givenViewModel()

        // When
        let task = Task { try await viewModel.markBookingAsPaid() }
        let action = try await waitForFirstBookingAction()
        guard case let .markBookingAsPaid(_, _, onCompletion) = action else {
            return XCTFail("Expected markBookingAsPaid action")
        }
        onCompletion(nil)
        try await task.value

        // Then
        analyticsProvider.assertReceived(event: "booking_detail_mark_as_paid_tapped")
    }

    func test_event_fired_when_booking_cancelled() async throws {
        // Given
        let viewModel = givenViewModel()

        // When
        let task = Task { try await viewModel.cancelBooking() }
        let action = try await waitForFirstBookingAction()
        guard case let .cancelBooking(_, _, onCompletion) = action else {
            return XCTFail("Expected cancelBooking action")
        }
        onCompletion(nil)
        try await task.value

        // Then
        analyticsProvider.assertReceived(event: "booking_detail_cancel_booking")
    }

    func test_event_fired_when_notes_tapped() {
        // Given
        let viewModel = givenViewModel()

        // When
        viewModel.notesTapped()

        // Then
        analyticsProvider.assertReceived(event: "booking_detail_add_note_tapped")
    }


}

private extension BookingDetailsViewModelTests {
    func givenViewModel(booking: Booking = Booking.fake()) -> BookingDetailsViewModel {
        return BookingDetailsViewModel(booking: booking, stores: storesManager, analytics: analytics)
    }

    func waitForFirstBookingAction(
        timeout: TimeInterval = 1,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> BookingAction {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if let action = storesManager.receivedActions.first as? BookingAction {
                return action
            }
            await Task.yield()
        }

        XCTFail("Timed out waiting for BookingAction to be dispatched", file: file, line: line)
        throw XCTSkip("No BookingAction dispatched")
    }
}

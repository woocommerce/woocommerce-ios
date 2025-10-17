import XCTest
import TestKit
import Yosemite
import Fakes

@testable import WooCommerce

@MainActor
final class BookingDetailsViewModelTests: XCTestCase {
    private var storesManager: MockStoresManager!
    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        storesManager = MockStoresManager(sessionManager: .makeForTesting())
        storageManager = MockStorageManager()
    }

    override func tearDown() {
        super.tearDown()
        storesManager = nil
        storageManager = nil
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
        let viewModel = BookingDetailsViewModel(booking: booking, stores: storesManager)

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
        let viewModel = BookingDetailsViewModel(booking: booking, stores: storesManager)

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

    func test_header_content_uses_booking_summary_text() {
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
        let viewModel = BookingDetailsViewModel(booking: booking, stores: storesManager)

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

        XCTAssertEqual(headerContent.serviceAndCustomerLine, "Massage Therapy  •  Jane Smith")
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
        let viewModel = BookingDetailsViewModel(booking: booking, stores: storesManager)

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

    func test_navigation_title_includes_booking_id() {
        // Given
        let booking = Booking.fake().copy(bookingID: 12345)

        // When
        let viewModel = BookingDetailsViewModel(booking: booking, stores: storesManager)

        // Then
        XCTAssertTrue(viewModel.navigationTitle.contains("12345"))
    }
}

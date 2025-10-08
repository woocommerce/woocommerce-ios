import XCTest
import TestKit
import Yosemite
import Storage
import Fakes
import Networking

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

    func test_load_local_data_when_customer_exists_in_storage_populates_customer_content() {
        // Given
        let expectation = self.expectation(description: "The view model's customer content should be populated.")
        let customerID: Int64 = 123
        let mockBooking = Networking.Booking.fake().copy(customerID: customerID)

        let billingAddress = Networking.Address.fake().copy(
            address1: "123 Fake St",
            address2: "Apt 4B",
            city: "Faketown",
            state: "FS",
            postcode: "12345",
            country: "FK",
            phone: "123-456-7890"
        )
        let mockReadOnlyCustomer = Networking.Customer.fake().copy(
            customerID: customerID,
            email: "john.doe@example.com",
            firstName: "John",
            lastName: "Doe",
            billing: billingAddress
        )

        let mockStorageCustomer = storageManager.insertSampleCustomer(readOnlyCustomer: mockReadOnlyCustomer)
        let viewModel = BookingDetailsViewModel(booking: mockBooking, stores: storesManager)

        storesManager.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .loadCustomer(_, _, onCompletion) = action else {
                return
            }
            onCompletion(.success(mockStorageCustomer.toReadOnly()))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
        }

        // When
        viewModel.loadLocalData()

        // Wait for async updates to finish
        wait(for: [expectation], timeout: 1.0)

        // Then
        let customerSection = viewModel.sections.first { if case .customer = $0.content { true } else { false } }
        guard let customerSection = customerSection,
              case let .customer(customerContent) = customerSection.content else {
            XCTFail("Customer section not found in view model sections")
            return
        }

        XCTAssertEqual(customerContent.nameText, "\(mockStorageCustomer.firstName ?? "") \(mockStorageCustomer.lastName ?? "")")
        XCTAssertEqual(customerContent.emailText, mockStorageCustomer.email)
        XCTAssertEqual(customerContent.phoneText, mockStorageCustomer.billingPhone)

        let expectedBillingAddress = [
            mockStorageCustomer.billingAddress1,
            mockStorageCustomer.billingAddress2,
            mockStorageCustomer.billingCity,
            mockStorageCustomer.billingState,
            mockStorageCustomer.billingPostcode,
            mockStorageCustomer.billingCountry
        ]
        .compactMap { $0 }
        .filter { !$0.isEmpty }
        .joined(separator: "\n")

        XCTAssertEqual(customerContent.billingAddressText, expectedBillingAddress)
    }

    func test_load_local_data_when_customer_exists_in_storage_populates_header_content() {
        // Given
        let expectation = self.expectation(description: "The view model's header content should be populated.")
        let customerID: Int64 = 123
        let mockBooking = Networking.Booking.fake().copy(customerID: customerID)

        let mockReadOnlyCustomer = Networking.Customer.fake().copy(
            customerID: customerID,
            firstName: "John",
            lastName: "Doe"
        )

        let mockStorageCustomer = storageManager.insertSampleCustomer(readOnlyCustomer: mockReadOnlyCustomer)
        let viewModel = BookingDetailsViewModel(booking: mockBooking, stores: storesManager)

        storesManager.whenReceivingAction(ofType: CustomerAction.self) { action in
            guard case let .loadCustomer(_, _, onCompletion) = action else {
                return
            }
            onCompletion(.success(mockStorageCustomer.toReadOnly()))
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                expectation.fulfill()
            }
        }

        // When
        viewModel.loadLocalData()

        // Wait for async updates to finish
        wait(for: [expectation], timeout: 1.0)

        // Then
        let headerSection = viewModel.sections.first { if case .header = $0.content { true } else { false } }
        guard let headerSection = headerSection,
              case let .header(headerContent) = headerSection.content else {
            XCTFail("Header section not found in view model sections")
            return
        }

        let expectedHeaderLine = "Women's Haircut • John Doe"
        XCTAssertEqual(headerContent.serviceAndCustomerLine, expectedHeaderLine)
    }
}

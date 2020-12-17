import XCTest
import TestKit
@testable import Yosemite
@testable import Networking
@testable import Storage

/// CustomerStore Unit Tests
///
final class CustomerStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Testing SiteID
    ///
    private let sampleSiteID: Int64 = 1234

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()

        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork(useResponseQueue: true)
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil

        super.tearDown()
    }

    // MARK: - CustomerAction.createCustomer

    func test_createCustomer_persists_customer() throws {
        // Given
        let store = CustomerStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "customers", filename: "customer")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 0)

        // When
        let customer = try sampleCustomer()
        let result: Result<Networking.Customer, Error> = try waitFor { promise in
            let action = CustomerAction.createCustomer(siteID: self.sampleSiteID, customer: customer) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 1)
    }

    func test_createCustomer_returns_error_on_failure() throws {
        // Given
        let store = CustomerStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectedError = NetworkError.notFound
        network.simulateError(requestUrlSuffix: "customers", error: expectedError)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 0)

        // When
        let customer = try sampleCustomer()
        let result: Result<Networking.Customer, Error> = try waitFor { promise in
            let action = CustomerAction.createCustomer(siteID: self.sampleSiteID, customer: customer) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 0)
    }

    // MARK: - CustomerAction.synchronizeAllCustomers

    func test_synchronizeAllCustomers_persists_all_pages_of_customers_on_success() throws {
        // Given
        let store = CustomerStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "customers", filename: "customers-all")
        network.simulateResponse(requestUrlSuffix: "customers", filename: "customers-extra")
        network.simulateResponse(requestUrlSuffix: "customers", filename: "customers-empty")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 0)

        // When
        let result: Result<Void, Error> = try waitFor { promise in
            let action = CustomerAction.synchronizeAllCustomers(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 3)
    }

    func test_synchronizeAllCustomers_persists_customer_details_on_success() throws {
        // Given
        let store = CustomerStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        network.simulateResponse(requestUrlSuffix: "customers", filename: "customers-all")
        network.simulateResponse(requestUrlSuffix: "customers", filename: "customers-empty")
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 0)
        let remoteCustomer = try sampleCustomer()

        // When
        let result: Result<Void, Error> = try waitFor { promise in
            let action = CustomerAction.synchronizeAllCustomers(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let storedCustomer = self.viewStorage.loadCustomer(siteID: remoteCustomer.siteID, userID: remoteCustomer.userID)
        let readOnlyCustomer = storedCustomer?.toReadOnly()
        XCTAssertNotNil(storedCustomer)
        XCTAssertNotNil(readOnlyCustomer)
        XCTAssertEqual(readOnlyCustomer, remoteCustomer)
    }

    func test_synchronizeAllCustomers_returns_error_on_failure() throws {
        // Given
        let store = CustomerStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        let expectedError = NetworkError.notFound
        network.simulateError(requestUrlSuffix: "customers", error: expectedError)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 0)

        // When
        let result: Result<Void, Error> = try waitFor { promise in
            let action = CustomerAction.synchronizeAllCustomers(siteID: self.sampleSiteID) { result in
                promise(result)
            }
            store.onAction(action)
        }

        // Then
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, expectedError)
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.Customer.self), 0)
    }
}


// MARK: - Private Helpers
//
private extension CustomerStoreTests {

    func sampleCustomer() throws -> Networking.Customer {
        let billingAddress = Networking.Address(firstName: "John",
                                                lastName: "Doe",
                                                company: "",
                                                address1: "969 Market",
                                                address2: "",
                                                city: "San Francisco",
                                                state: "CA",
                                                postcode: "94103",
                                                country: "US",
                                                phone: "(555) 555-5555",
                                                email: "john.doe@example.com")

        let shippingAddress = Networking.Address(firstName: "John",
                                                 lastName: "Doe",
                                                 company: "",
                                                 address1: "969 Market",
                                                 address2: "",
                                                 city: "San Francisco",
                                                 state: "CA",
                                                 postcode: "94103",
                                                 country: "US",
                                                 phone: nil,
                                                 email: nil)

        let johnDoeID: Int64 = 25
        let dateCreated = try XCTUnwrap(DateFormatter.Defaults.dateTimeFormatter.date(from: "2017-03-21T19:09:28"))
        let dateModified = try XCTUnwrap(DateFormatter.Defaults.dateTimeFormatter.date(from: "2017-03-21T19:09:30"))
        let johnDoe = Networking.Customer(siteID: sampleSiteID,
                                          userID: johnDoeID,
                                          dateCreated: dateCreated,
                                          dateModified: dateModified,
                                          email: "john.doe@example.com",
                                          username: "john.doe",
                                          firstName: "John",
                                          lastName: "Doe",
                                          avatarUrl: "https://secure.gravatar.com/avatar/8eb1b522f60d11fa897de1dc6351b7e8?s=96",
                                          role: .customer,
                                          isPaying: false,
                                          billingAddress: billingAddress,
                                          shippingAddress: shippingAddress)
        return johnDoe
    }
}

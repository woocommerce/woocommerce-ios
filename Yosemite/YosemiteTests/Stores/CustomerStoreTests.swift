import XCTest
@testable import Networking
@testable import Yosemite

class CustomerStoreTests: XCTestCase {

    private var dispatcher: Dispatcher!
    private var storageManager: MockStorageManager!
    private var network: MockNetwork!
    private var remote: CustomerRemote!
    private var store: CustomerStore!
    private let dummySiteID: Int64 = 12345
    private let dummyCustomerID: Int64 = 1

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = CustomerRemote(network: network)
        store = CustomerStore(
            dispatcher: dispatcher,
            storageManager: storageManager,
            network: network,
            remote: remote
        )
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        remote = nil
        store = nil
        super.tearDown()
    }

    func test_retrieveCustomer_returns_Customer_upon_success() {
        // Given
        network.simulateResponse(requestUrlSuffix: "customers/\(dummyCustomerID)", filename: "customer")

        // When
        let result: Result<Customer, Error> = waitFor { promise in
            let action = CustomerAction.retrieveCustomer(siteID: self.dummySiteID, customerID: self.dummyCustomerID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_retrieveCustomer_returns_notFound_Error_upon_siteID_error() {
        // Given
        let expectedError = NetworkError.notFound
        network.simulateError(requestUrlSuffix: "customers/\(dummyCustomerID)", error: expectedError)

        // When
        let result: Result<Customer, Error> = waitFor { promise in
            let action = CustomerAction.retrieveCustomer(siteID: 999, customerID: self.dummyCustomerID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_retrieveCustomer_returns_Error_upon_customerID_error() {
        let expectedError = NetworkError.notFound
        network.simulateError(requestUrlSuffix: "customers/999", error: expectedError )

        // When
        let result: Result<Customer, Error> = waitFor { promise in
            let action = CustomerAction.retrieveCustomer(siteID: self.dummySiteID, customerID: self.dummyCustomerID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }

    func test_retrieveCustomer_returns_notFound_Error_upon_network_error() {
        // Given
        let expectedError = NetworkError.notFound
        network.simulateError(requestUrlSuffix: "customers/\(dummyCustomerID)", error: expectedError)

        // When
        let result: Result<Customer, Error> = waitFor { promise in
            let action = CustomerAction.retrieveCustomer(siteID: self.dummySiteID, customerID: self.dummyCustomerID) { result in
                promise(result)
            }
            self.store.onAction(action)
        }

        // Then
        XCTAssertTrue(result.isFailure)
        XCTAssertEqual(result.failure as? NetworkError, expectedError)
    }
}

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

    func test_retrieveCustomer_returns_Customer_upon_success() {
        // Given
        network.simulateResponse(requestUrlSuffix: "", filename: "customer")

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

    func test_retrieveCustomer_returns_Error_upon_failure() {
        // Given
        let expectedError = NetworkError.notFound
        network.simulateError(requestUrlSuffix: "", error: expectedError)

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

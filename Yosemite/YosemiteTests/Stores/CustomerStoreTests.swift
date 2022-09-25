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

    func test_retrieveCustomer_calls_remote_using_correct_request_parameters() {
        // Given
        let action = CustomerAction.retrieveCustomer(
            siteID: dummySiteID,
            customerID: dummyCustomerID,
            onCompletion: { _ in }
        )

        // When
        store.onAction(action)

        // Then
        // ...

    }
}
